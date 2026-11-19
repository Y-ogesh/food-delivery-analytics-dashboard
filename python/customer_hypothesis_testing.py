"""Run validated customer spending hypothesis tests.

This workflow validates the SQL extraction, reproduces descriptive statistics,
runs prespecified two-sided tests, calculates effect sizes and deterministic
bootstrap intervals, and creates aggregate publication-quality figures.

Connection configuration, in priority order:
1. DATABASE_URL (for example, a SQLAlchemy PostgreSQL URL).
2. Standard PostgreSQL variables: PGDATABASE, PGUSER, PGPASSWORD, PGHOST,
   and PGPORT. PGDATABASE defaults to food_delivery_analytics; other omitted
   values are left to the local PostgreSQL/libpq defaults.
"""

from __future__ import annotations

import os
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import levene, mannwhitneyu, skew, ttest_ind
from sqlalchemy import URL, create_engine, text
from sqlalchemy.engine import Engine


PROJECT_ROOT = Path(__file__).resolve().parents[1]
EXTRACTION_SQL_PATH = PROJECT_ROOT / "sql" / "06_customer_spending_extraction.sql"
FIGURE_PATH = (
    PROJECT_ROOT
    / "images"
    / "statistical_analysis"
    / "customer_average_delivered_order_value_distributions.png"
)
BOXPLOT_PATH = (
    PROJECT_ROOT
    / "images"
    / "statistical_analysis"
    / "customer_spending_boxplots.png"
)
ECDF_PATH = (
    PROJECT_ROOT
    / "images"
    / "statistical_analysis"
    / "customer_spending_ecdf.png"
)
BOOTSTRAP_FIGURE_PATH = (
    PROJECT_ROOT
    / "images"
    / "statistical_analysis"
    / "customer_spending_bootstrap_confidence_intervals.png"
)

ALPHA = 0.05
BOOTSTRAP_RESAMPLES = 10_000
RANDOM_SEED = 20_261_119

EXPECTED_BENCHMARKS = {
    "delivered_orders": 21_131,
    "eligible_customers": 11_545,
    "one_time_customers": 7_691,
    "one_time_customer_pct": 66.62,
    "repeat_customers": 3_854,
    "repeat_customer_pct": 33.38,
    "missing_delivered_order_values": 0,
    "non_positive_delivered_order_values": 0,
    "minimum_order_value": 52.50,
    "maximum_order_value": 12_663.00,
    "overall_order_level_average": 682.57,
}

EXPECTED_DESCRIPTIVE_STATISTICS = {
    "One-time": {
        "customers": 7_691,
        "mean": 699.62,
        "median": 609.00,
        "standard_deviation": 506.64,
        "q1": 394.90,
        "q3": 848.66,
        "skewness": 5.64,
    },
    "Repeat": {
        "customers": 3_854,
        "mean": 688.13,
        "median": 628.02,
        "standard_deviation": 365.51,
        "q1": 450.71,
        "q3": 834.40,
        "skewness": 2.73,
    },
}

ORDER_VALIDATION_SQL = text(
    """
    SELECT
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (WHERE total IS NULL)
            AS missing_delivered_order_values,
        COUNT(*) FILTER (WHERE total <= 0)
            AS non_positive_delivered_order_values,
        MIN(total)::DOUBLE PRECISION AS minimum_order_value,
        MAX(total)::DOUBLE PRECISION AS maximum_order_value,
        AVG(total)::DOUBLE PRECISION AS overall_order_level_average
    FROM public.clean_orders
    WHERE order_status = 'Delivered'
    """
)


def build_engine() -> Engine:
    """Create a PostgreSQL engine without embedding credentials in code."""
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return create_engine(database_url)

    port = int(os.environ["PGPORT"]) if os.getenv("PGPORT") else None
    connection_url = URL.create(
        drivername="postgresql+psycopg",
        username=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOST"),
        port=port,
        database=os.getenv("PGDATABASE", "food_delivery_analytics"),
    )
    return create_engine(connection_url)


def read_customer_data(engine: Engine) -> pd.DataFrame:
    """Run the version-controlled customer-level extraction query."""
    extraction_sql = EXTRACTION_SQL_PATH.read_text(encoding="utf-8")
    return pd.read_sql_query(text(extraction_sql), engine)


def read_order_benchmarks(engine: Engine) -> dict[str, float | int]:
    """Read order-level quality benchmarks from Delivered orders."""
    with engine.connect() as connection:
        row = connection.execute(ORDER_VALIDATION_SQL).mappings().one()
    return dict(row)


def assert_equal(actual: int, expected: int, metric: str) -> None:
    if actual != expected:
        raise ValueError(f"{metric}: expected {expected:,}, found {actual:,}")


def assert_close(
    actual: float,
    expected: float,
    metric: str,
    tolerance: float = 0.005,
) -> None:
    if not np.isclose(actual, expected, atol=tolerance, rtol=0):
        raise ValueError(f"{metric}: expected {expected:,.2f}, found {actual:,.6f}")


def validate_data(
    customer_data: pd.DataFrame,
    order_benchmarks: dict[str, float | int],
) -> pd.DataFrame:
    """Validate extraction grain, classifications, and verified benchmarks."""
    required_columns = {
        "customer_id",
        "delivered_order_count",
        "average_delivered_order_value",
        "customer_segment",
    }
    missing_columns = required_columns.difference(customer_data.columns)
    if missing_columns:
        raise ValueError(f"Extraction is missing columns: {sorted(missing_columns)}")

    if customer_data["customer_id"].isna().any():
        raise ValueError("Extracted customer_id contains NULL values")
    if customer_data["customer_id"].duplicated().any():
        raise ValueError("Extraction is not at one row per customer")
    if customer_data["average_delivered_order_value"].isna().any():
        raise ValueError("Customer average delivered order value contains NULL values")
    if (customer_data["average_delivered_order_value"] <= 0).any():
        raise ValueError("Customer average delivered order value contains non-positive values")

    expected_segment = np.where(
        customer_data["delivered_order_count"].eq(1),
        "One-time",
        "Repeat",
    )
    if not np.array_equal(customer_data["customer_segment"], expected_segment):
        raise ValueError("Customer segment labels do not match delivered-order counts")

    segment_counts = customer_data["customer_segment"].value_counts()
    assert_equal(
        int(order_benchmarks["delivered_orders"]),
        EXPECTED_BENCHMARKS["delivered_orders"],
        "Delivered orders",
    )
    assert_equal(
        len(customer_data),
        EXPECTED_BENCHMARKS["eligible_customers"],
        "Eligible customers",
    )
    assert_equal(
        int(segment_counts.get("One-time", 0)),
        EXPECTED_BENCHMARKS["one_time_customers"],
        "One-time customers",
    )
    assert_equal(
        int(segment_counts.get("Repeat", 0)),
        EXPECTED_BENCHMARKS["repeat_customers"],
        "Repeat customers",
    )
    assert_close(
        100.0 * int(segment_counts.get("One-time", 0)) / len(customer_data),
        EXPECTED_BENCHMARKS["one_time_customer_pct"],
        "One-time customer percentage",
    )
    assert_close(
        100.0 * int(segment_counts.get("Repeat", 0)) / len(customer_data),
        EXPECTED_BENCHMARKS["repeat_customer_pct"],
        "Repeat customer percentage",
    )
    assert_equal(
        int(order_benchmarks["missing_delivered_order_values"]),
        EXPECTED_BENCHMARKS["missing_delivered_order_values"],
        "Missing delivered order values",
    )
    assert_equal(
        int(order_benchmarks["non_positive_delivered_order_values"]),
        EXPECTED_BENCHMARKS["non_positive_delivered_order_values"],
        "Non-positive delivered order values",
    )
    assert_close(
        float(order_benchmarks["minimum_order_value"]),
        EXPECTED_BENCHMARKS["minimum_order_value"],
        "Minimum order value",
    )
    assert_close(
        float(order_benchmarks["maximum_order_value"]),
        EXPECTED_BENCHMARKS["maximum_order_value"],
        "Maximum order value",
    )
    assert_close(
        float(order_benchmarks["overall_order_level_average"]),
        EXPECTED_BENCHMARKS["overall_order_level_average"],
        "Overall order-level average",
    )

    print("Validation passed against all verified SQL benchmarks.")
    segment_summary = segment_counts.rename_axis("customer_segment").reset_index(
        name="customers"
    )
    segment_summary["customer_pct"] = (
        100.0 * segment_summary["customers"] / len(customer_data)
    )
    return segment_summary


def calculate_descriptive_statistics(customer_data: pd.DataFrame) -> pd.DataFrame:
    """Calculate segment-level customer average spending summaries."""
    records: list[dict[str, float | int | str]] = []
    segment_order = ["One-time", "Repeat"]

    for segment in segment_order:
        values = customer_data.loc[
            customer_data["customer_segment"].eq(segment),
            "average_delivered_order_value",
        ].astype(float)
        records.append(
            {
                "customer_segment": segment,
                "customers": int(values.size),
                "mean": values.mean(),
                "median": values.median(),
                "standard_deviation": values.std(ddof=1),
                "minimum": values.min(),
                "q1": values.quantile(0.25),
                "q3": values.quantile(0.75),
                "maximum": values.max(),
                "skewness": skew(values, bias=False, nan_policy="raise"),
            }
        )

    return pd.DataFrame.from_records(records).set_index("customer_segment")


def validate_descriptive_statistics(statistics: pd.DataFrame) -> None:
    """Confirm the current run reproduces the previously validated summaries."""
    for segment, expected_values in EXPECTED_DESCRIPTIVE_STATISTICS.items():
        actual = statistics.loc[segment]
        assert_equal(
            int(actual["customers"]),
            int(expected_values["customers"]),
            f"{segment} descriptive customer count",
        )
        for metric in (
            "mean",
            "median",
            "standard_deviation",
            "q1",
            "q3",
            "skewness",
        ):
            assert_close(
                float(actual[metric]),
                float(expected_values[metric]),
                f"{segment} descriptive {metric}",
                tolerance=0.01,
            )
    print("Descriptive statistics match the previously validated results.")


def hedges_g(repeat: np.ndarray, one_time: np.ndarray) -> float:
    """Calculate bias-corrected standardized mean difference (Repeat - One-time)."""
    repeat_variance = repeat.var(ddof=1)
    one_time_variance = one_time.var(ddof=1)
    degrees_of_freedom = repeat.size + one_time.size - 2
    pooled_sd = np.sqrt(
        (
            (repeat.size - 1) * repeat_variance
            + (one_time.size - 1) * one_time_variance
        )
        / degrees_of_freedom
    )
    correction = 1.0 - 3.0 / (4.0 * (repeat.size + one_time.size) - 9.0)
    return float(correction * (repeat.mean() - one_time.mean()) / pooled_sd)


def run_hypothesis_tests(
    repeat: np.ndarray,
    one_time: np.ndarray,
) -> pd.DataFrame:
    """Run prespecified two-sided tests; directional effects are Repeat - One-time."""
    mann_whitney = mannwhitneyu(
        repeat,
        one_time,
        alternative="two-sided",
        method="asymptotic",
    )
    cliffs_delta = 2.0 * float(mann_whitney.statistic) / (
        repeat.size * one_time.size
    ) - 1.0

    welch_original = ttest_ind(
        repeat,
        one_time,
        equal_var=False,
        alternative="two-sided",
    )

    log_repeat = np.log(repeat)
    log_one_time = np.log(one_time)
    welch_log = ttest_ind(
        log_repeat,
        log_one_time,
        equal_var=False,
        alternative="two-sided",
    )

    brown_forsythe = levene(
        repeat,
        one_time,
        center="median",
    )

    records = [
        {
            "analysis": "Mann-Whitney U",
            "statistic": float(mann_whitney.statistic),
            "degrees_of_freedom": np.nan,
            "p_value": float(mann_whitney.pvalue),
            "effect_name": "Cliff's delta",
            "effect_size": cliffs_delta,
            "significant": bool(mann_whitney.pvalue < ALPHA),
        },
        {
            "analysis": "Welch t-test (original)",
            "statistic": float(welch_original.statistic),
            "degrees_of_freedom": float(welch_original.df),
            "p_value": float(welch_original.pvalue),
            "effect_name": "Hedges' g",
            "effect_size": hedges_g(repeat, one_time),
            "significant": bool(welch_original.pvalue < ALPHA),
        },
        {
            "analysis": "Welch t-test (natural log)",
            "statistic": float(welch_log.statistic),
            "degrees_of_freedom": float(welch_log.df),
            "p_value": float(welch_log.pvalue),
            "effect_name": "Hedges' g (log scale)",
            "effect_size": hedges_g(log_repeat, log_one_time),
            "significant": bool(welch_log.pvalue < ALPHA),
        },
        {
            "analysis": "Brown-Forsythe",
            "statistic": float(brown_forsythe.statistic),
            "degrees_of_freedom": float(repeat.size + one_time.size - 2),
            "p_value": float(brown_forsythe.pvalue),
            "effect_name": "Variance ratio (Repeat / One-time)",
            "effect_size": float(repeat.var(ddof=1) / one_time.var(ddof=1)),
            "significant": bool(brown_forsythe.pvalue < ALPHA),
        },
    ]
    return pd.DataFrame.from_records(records).set_index("analysis")


def bootstrap_differences(
    repeat: np.ndarray,
    one_time: np.ndarray,
    resamples: int = BOOTSTRAP_RESAMPLES,
    seed: int = RANDOM_SEED,
    batch_size: int = 200,
) -> tuple[pd.DataFrame, dict[str, np.ndarray]]:
    """Bootstrap Repeat - One-time mean and median differences in bounded batches."""
    rng = np.random.default_rng(seed)
    mean_differences = np.empty(resamples, dtype=float)
    median_differences = np.empty(resamples, dtype=float)

    for start in range(0, resamples, batch_size):
        stop = min(start + batch_size, resamples)
        current_batch = stop - start
        repeat_samples = rng.choice(
            repeat,
            size=(current_batch, repeat.size),
            replace=True,
        )
        one_time_samples = rng.choice(
            one_time,
            size=(current_batch, one_time.size),
            replace=True,
        )
        mean_differences[start:stop] = (
            repeat_samples.mean(axis=1) - one_time_samples.mean(axis=1)
        )
        median_differences[start:stop] = (
            np.median(repeat_samples, axis=1)
            - np.median(one_time_samples, axis=1)
        )

    observed_mean_difference = float(repeat.mean() - one_time.mean())
    observed_median_difference = float(np.median(repeat) - np.median(one_time))
    mean_ci = np.percentile(mean_differences, [2.5, 97.5])
    median_ci = np.percentile(median_differences, [2.5, 97.5])

    summary = pd.DataFrame.from_records(
        [
            {
                "metric": "Mean difference",
                "difference": observed_mean_difference,
                "percentage_difference": 100.0
                * observed_mean_difference
                / one_time.mean(),
                "ci_95_lower": float(mean_ci[0]),
                "ci_95_upper": float(mean_ci[1]),
            },
            {
                "metric": "Median difference",
                "difference": observed_median_difference,
                "percentage_difference": 100.0
                * observed_median_difference
                / np.median(one_time),
                "ci_95_lower": float(median_ci[0]),
                "ci_95_upper": float(median_ci[1]),
            },
        ]
    ).set_index("metric")
    distributions = {
        "Mean difference": mean_differences,
        "Median difference": median_differences,
    }
    return summary, distributions


def create_distribution_figure(customer_data: pd.DataFrame) -> Path:
    """Save aggregate distribution plots without exporting customer-level data."""
    FIGURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    plot_data = customer_data.copy()
    upper_limit = float(
        plot_data["average_delivered_order_value"].quantile(0.99)
    )

    sns.set_theme(style="whitegrid", context="notebook")
    figure, axes = plt.subplots(1, 2, figsize=(14, 5.5))

    sns.histplot(
        data=plot_data,
        x="average_delivered_order_value",
        hue="customer_segment",
        hue_order=["One-time", "Repeat"],
        bins=50,
        stat="density",
        common_norm=False,
        element="step",
        fill=False,
        ax=axes[0],
    )
    axes[0].set_xlim(0, upper_limit)
    axes[0].set_title("Customer Average Delivered Order Value\n(Displayed Through 99th Percentile)")
    axes[0].set_xlabel("Average delivered order value")
    axes[0].set_ylabel("Density")

    sns.boxplot(
        data=plot_data,
        x="customer_segment",
        y="average_delivered_order_value",
        order=["One-time", "Repeat"],
        hue="customer_segment",
        hue_order=["One-time", "Repeat"],
        legend=False,
        ax=axes[1],
    )
    axes[1].set_yscale("log")
    axes[1].set_title("Customer Average Delivered Order Value\n(Log Scale; All Values)")
    axes[1].set_xlabel("Customer segment")
    axes[1].set_ylabel("Average delivered order value (log scale)")

    figure.suptitle("Delivered Order Value Distributions by Customer Segment", fontsize=15)
    figure.tight_layout()
    figure.savefig(FIGURE_PATH, dpi=180, bbox_inches="tight")
    plt.close(figure)
    return FIGURE_PATH


def create_boxplot_figure(customer_data: pd.DataFrame) -> Path:
    """Create a publication-quality box plot retaining all valid observations."""
    BOXPLOT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sns.set_theme(style="whitegrid", context="talk")
    palette = {"One-time": "#4C78A8", "Repeat": "#F58518"}
    figure, axis = plt.subplots(figsize=(9, 6.5))
    sns.boxplot(
        data=customer_data,
        x="customer_segment",
        y="average_delivered_order_value",
        order=["One-time", "Repeat"],
        hue="customer_segment",
        palette=palette,
        legend=False,
        width=0.55,
        showfliers=True,
        ax=axis,
    )
    axis.set_yscale("log")
    axis.set_title("Customer Average Delivered Order Value by Segment")
    axis.set_xlabel("Customer segment")
    axis.set_ylabel("Average delivered order value (log scale)")
    axis.text(
        0.01,
        0.01,
        "All valid observations retained; logarithmic scale used for visibility.",
        transform=axis.transAxes,
        fontsize=10,
        color="#444444",
    )
    figure.tight_layout()
    figure.savefig(BOXPLOT_PATH, dpi=220, bbox_inches="tight")
    plt.close(figure)
    return BOXPLOT_PATH


def create_ecdf_figure(customer_data: pd.DataFrame) -> Path:
    """Create an empirical cumulative distribution comparison."""
    ECDF_PATH.parent.mkdir(parents=True, exist_ok=True)
    sns.set_theme(style="whitegrid", context="talk")
    palette = {"One-time": "#4C78A8", "Repeat": "#F58518"}
    figure, axis = plt.subplots(figsize=(9, 6.5))
    sns.ecdfplot(
        data=customer_data,
        x="average_delivered_order_value",
        hue="customer_segment",
        hue_order=["One-time", "Repeat"],
        palette=palette,
        linewidth=2.2,
        ax=axis,
    )
    axis.set_xscale("log")
    axis.set_title("ECDF of Customer Average Delivered Order Value")
    axis.set_xlabel("Average delivered order value (log scale)")
    axis.set_ylabel("Cumulative proportion of customers")
    axis.set_ylim(0, 1.01)
    legend = axis.get_legend()
    if legend is not None:
        legend.set_title("Customer segment")
        legend.get_title().set_fontsize(11)
        for label in legend.get_texts():
            label.set_fontsize(11)
    figure.tight_layout()
    figure.savefig(ECDF_PATH, dpi=220, bbox_inches="tight")
    plt.close(figure)
    return ECDF_PATH


def create_bootstrap_figure(
    bootstrap_summary: pd.DataFrame,
    bootstrap_distributions: dict[str, np.ndarray],
) -> Path:
    """Plot bootstrap distributions and percentile confidence intervals."""
    BOOTSTRAP_FIGURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    sns.set_theme(style="whitegrid", context="talk")
    colors = {"Mean difference": "#4C78A8", "Median difference": "#F58518"}
    figure, axes = plt.subplots(1, 2, figsize=(14, 5.8))

    for axis, metric in zip(axes, ("Mean difference", "Median difference")):
        distribution = bootstrap_distributions[metric]
        result = bootstrap_summary.loc[metric]
        sns.histplot(
            distribution,
            bins=55,
            stat="density",
            color=colors[metric],
            alpha=0.55,
            edgecolor="white",
            ax=axis,
        )
        axis.axvline(0, color="#333333", linestyle="--", linewidth=1.5, label="No difference")
        axis.axvline(
            result["difference"],
            color=colors[metric],
            linewidth=2.5,
            label="Observed difference",
        )
        axis.axvspan(
            result["ci_95_lower"],
            result["ci_95_upper"],
            color=colors[metric],
            alpha=0.18,
            label="Bootstrap 95% CI",
        )
        axis.set_title(metric)
        axis.set_xlabel("Repeat − One-time")
        axis.set_ylabel("Bootstrap density")
        axis.legend(fontsize=9)

    figure.suptitle(
        f"Bootstrap Differences in Customer Average Delivered Order Value\n"
        f"{BOOTSTRAP_RESAMPLES:,} resamples · seed {RANDOM_SEED}",
        fontsize=16,
    )
    figure.tight_layout()
    figure.savefig(BOOTSTRAP_FIGURE_PATH, dpi=220, bbox_inches="tight")
    plt.close(figure)
    return BOOTSTRAP_FIGURE_PATH


def main() -> None:
    engine = build_engine()
    try:
        customer_data = read_customer_data(engine)
        order_benchmarks = read_order_benchmarks(engine)
    finally:
        engine.dispose()

    segment_counts = validate_data(customer_data, order_benchmarks)
    descriptive_statistics = calculate_descriptive_statistics(customer_data)
    validate_descriptive_statistics(descriptive_statistics)

    one_time = customer_data.loc[
        customer_data["customer_segment"].eq("One-time"),
        "average_delivered_order_value",
    ].to_numpy(dtype=float)
    repeat = customer_data.loc[
        customer_data["customer_segment"].eq("Repeat"),
        "average_delivered_order_value",
    ].to_numpy(dtype=float)

    test_results = run_hypothesis_tests(repeat, one_time)
    bootstrap_summary, bootstrap_distributions = bootstrap_differences(
        repeat,
        one_time,
    )

    figure_paths = [
        create_distribution_figure(customer_data),
        create_boxplot_figure(customer_data),
        create_ecdf_figure(customer_data),
        create_bootstrap_figure(bootstrap_summary, bootstrap_distributions),
    ]

    print("\nCustomer segment counts:")
    print(segment_counts.to_string(index=False))
    print("\nDescriptive statistics:")
    print(descriptive_statistics.round(2).to_string())
    print(f"\nTwo-sided hypothesis tests (alpha = {ALPHA}):")
    with pd.option_context("display.float_format", "{:.12g}".format):
        print(test_results.to_string())
    print(
        f"\nBootstrap differences (Repeat - One-time; "
        f"{BOOTSTRAP_RESAMPLES:,} resamples; seed = {RANDOM_SEED}):"
    )
    print(bootstrap_summary.round(6).to_string())
    repeat_geometric_mean = float(np.exp(np.log(repeat).mean()))
    one_time_geometric_mean = float(np.exp(np.log(one_time).mean()))
    geometric_mean_pct_difference = (
        100.0 * (repeat_geometric_mean - one_time_geometric_mean)
        / one_time_geometric_mean
    )
    print("\nSupplementary log-scale summary:")
    print(f"One-time geometric mean: {one_time_geometric_mean:.6f}")
    print(f"Repeat geometric mean: {repeat_geometric_mean:.6f}")
    print(
        "Geometric mean percentage difference (Repeat - One-time): "
        f"{geometric_mean_pct_difference:.6f}%"
    )
    print("\nFigures:")
    for figure_path in figure_paths:
        print(f"- {figure_path.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
