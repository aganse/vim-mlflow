"""Lightweight helpers to build fake MLflow objects for tests."""

from types import SimpleNamespace
from typing import Dict, Iterable, Optional


def make_experiment(exp_id: int, name: str, lifecycle: str = "active") -> SimpleNamespace:
    """Return a minimal stand-in for mlflow.entities.Experiment."""
    return SimpleNamespace(
        experiment_id=str(exp_id),
        name=name,
        lifecycle_stage=lifecycle,
    )


def make_run(
    run_id: str,
    start_time_ms: Optional[int],
    end_time_ms: Optional[int],
    *,
    status: str = "FINISHED",
    lifecycle_stage: str = "active",
    user_id: str = "user",
    run_name: str = "",
    tags: Optional[Dict[str, str]] = None,
    metrics: Optional[Dict[str, float]] = None,
) -> SimpleNamespace:
    """Return a minimal stand-in for mlflow.entities.Run."""
    merged_tags = {"mlflow.user": user_id}
    if run_name:
        merged_tags["mlflow.runName"] = run_name
    if tags:
        merged_tags.update(tags)

    run_metrics = metrics or {}

    info = SimpleNamespace(
        run_id=run_id,
        start_time=start_time_ms,
        end_time=end_time_ms,
        status=status,
        lifecycle_stage=lifecycle_stage,
        user_id=user_id,
        run_name=run_name,
    )
    data = SimpleNamespace(
        tags=merged_tags,
        metrics=run_metrics,
    )
    return SimpleNamespace(info=info, data=data)


def make_metric_history(values: Iterable[float], *, start_step: int = 0) -> list:
    """Build a sequence that mimics mlflow.entities.Metric."""
    history = []
    timestamp = 1_700_000_000_000
    for idx, value in enumerate(values, start=start_step):
        history.append(
            SimpleNamespace(
                step=idx,
                timestamp=timestamp + idx * 1000,
                value=value,
            )
        )
    return history
