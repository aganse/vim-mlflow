"""Session cache for MLflow data used by vim-mlflow."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
from urllib.request import urlopen

import pandas as pd
from mlflow.tracking import MlflowClient

from vim_mlflow_utils import format_run_duration


def _verify_tracking_url(url: str, timeout: float = 1.0) -> bool:
    """Check that the MLflow URL is running and accessible."""
    if not url.startswith("http"):
        raise RuntimeError("Incorrect and possibly insecure protocol in url")

    try:
        return urlopen(url, timeout=timeout).getcode() == 200
    except Exception:
        return False


def _format_timestamp(timestamp_ms: Optional[int]) -> str:
    """Format an MLflow timestamp in UTC for sidebar display."""
    if not timestamp_ms:
        return "N/A"
    return datetime.fromtimestamp(timestamp_ms / 1e3, tz=timezone.utc).strftime(
        "%Y-%m-%d %H:%M:%S"
    )


def _normalize_experiment(experiment: Any) -> Dict[str, str]:
    """Normalize an MLflow experiment entity into one dataframe row."""
    return {
        "experiment_id": str(experiment.experiment_id),
        "name": experiment.name,
        "lifecycle_stage": getattr(experiment, "lifecycle_stage", "active") or "active",
    }


def _normalize_run_summary(run: Any) -> Dict[str, Any]:
    """Normalize a run entity into a cached summary row."""
    run_tags = getattr(run.data, "tags", {}) or {}
    info = run.info
    duration_seconds = None
    if info.start_time and info.end_time:
        duration_seconds = (info.end_time - info.start_time) / 1e3

    return {
        "run_id": info.run_id,
        "run_id_short": info.run_id[:5],
        "experiment_id": str(info.experiment_id),
        "lifecycle_stage": getattr(info, "lifecycle_stage", "active") or "active",
        "start_time_ms": info.start_time,
        "end_time_ms": info.end_time,
        "start_time": _format_timestamp(info.start_time),
        "status": info.status or "-",
        "user": run_tags.get("mlflow.user") or getattr(info, "user_id", None) or "-",
        "run_name": getattr(info, "run_name", "") or run_tags.get("mlflow.runName", ""),
        "duration_seconds": duration_seconds,
        "duration": format_run_duration(duration_seconds),
    }


def _run_detail_to_dict(run: Any) -> Dict[str, Any]:
    """Normalize a detailed run entity into cached dict form."""
    info = run.info
    run_data = run.data
    return {
        "info": {
            "run_id": info.run_id,
            "experiment_id": str(info.experiment_id),
            "run_name": getattr(info, "run_name", "") or "",
            "status": info.status or "-",
            "lifecycle_stage": getattr(info, "lifecycle_stage", "active") or "active",
            "start_time": info.start_time,
            "end_time": info.end_time,
            "user_id": getattr(info, "user_id", None),
        },
        "data": {
            "params": dict(getattr(run_data, "params", {}) or {}),
            "metrics": dict(getattr(run_data, "metrics", {}) or {}),
            "tags": dict(getattr(run_data, "tags", {}) or {}),
        },
    }


@dataclass
class MlflowSessionCache:
    """Hold cached MLflow data for one tracking-uri/view/mode combination."""

    tracking_uri: str
    view_type: Any
    cache_mode: str
    timeout: float
    client: MlflowClient = field(init=False)
    experiments_df: pd.DataFrame = field(default_factory=pd.DataFrame)
    runs_by_experiment: Dict[str, pd.DataFrame] = field(default_factory=dict)
    run_details_by_id: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    metric_history_by_run: Dict[str, Dict[str, List[Dict[str, Any]]]] = field(
        default_factory=dict
    )
    artifacts_by_run: Dict[Tuple[str, int], List[Dict[str, Any]]] = field(
        default_factory=dict
    )
    available: Optional[bool] = None

    def __post_init__(self) -> None:
        self.client = MlflowClient(tracking_uri=self.tracking_uri)

    def invalidate(self) -> None:
        """Drop all cached data for this session."""
        self.experiments_df = pd.DataFrame()
        self.runs_by_experiment = {}
        self.run_details_by_id = {}
        self.metric_history_by_run = {}
        self.artifacts_by_run = {}
        self.available = None

    def ensure_available(self, force_refresh: bool = False) -> bool:
        """Verify the tracking server once per cache lifetime."""
        if force_refresh:
            self.available = None
        if self.available is None:
            self.available = _verify_tracking_url(self.tracking_uri, timeout=self.timeout)
        return bool(self.available)

    def get_experiments_df(self, force_refresh: bool = False) -> pd.DataFrame:
        """Return cached experiments as a normalized dataframe."""
        if force_refresh:
            self.experiments_df = pd.DataFrame()
        if self.experiments_df.empty:
            experiments = self.client.search_experiments(view_type=self.view_type)
            rows = [_normalize_experiment(experiment) for experiment in experiments]
            experiments_df = pd.DataFrame(rows)
            if experiments_df.empty:
                experiments_df = pd.DataFrame(
                    columns=["experiment_id", "name", "lifecycle_stage", "experiment_sort"]
                )
            else:
                experiments_df["experiment_sort"] = pd.to_numeric(
                    experiments_df["experiment_id"], errors="coerce"
                )
                experiments_df = experiments_df.sort_values(
                    ["experiment_sort", "experiment_id"], ascending=False, na_position="last"
                )
            self.experiments_df = experiments_df.reset_index(drop=True)
        return self.experiments_df

    def get_runs_df(self, experiment_id: str, force_refresh: bool = False) -> pd.DataFrame:
        """Return cached run summaries for one experiment."""
        experiment_id = str(experiment_id)
        if force_refresh:
            self.runs_by_experiment.pop(experiment_id, None)
        if experiment_id not in self.runs_by_experiment:
            runs = self.client.search_runs([experiment_id], run_view_type=self.view_type)
            rows = [_normalize_run_summary(run) for run in runs]
            runs_df = pd.DataFrame(rows)
            if runs_df.empty:
                runs_df = pd.DataFrame(
                    columns=[
                        "run_id",
                        "run_id_short",
                        "experiment_id",
                        "lifecycle_stage",
                        "start_time_ms",
                        "end_time_ms",
                        "start_time",
                        "status",
                        "user",
                        "run_name",
                        "duration_seconds",
                        "duration",
                    ]
                )
            else:
                runs_df = runs_df.sort_values(
                    ["start_time_ms", "run_id"], ascending=[False, True], na_position="last"
                )
            self.runs_by_experiment[experiment_id] = runs_df.reset_index(drop=True)
        return self.runs_by_experiment[experiment_id]

    def get_all_runs_df(self, force_refresh: bool = False) -> pd.DataFrame:
        """Return cached run summaries for all experiments combined."""
        experiment_ids = self.get_experiments_df(force_refresh=force_refresh)[
            "experiment_id"
        ].tolist()
        run_frames = [
            self.get_runs_df(experiment_id, force_refresh=force_refresh)
            for experiment_id in experiment_ids
        ]
        if not run_frames:
            return pd.DataFrame()
        non_empty_frames = [frame for frame in run_frames if not frame.empty]
        if not non_empty_frames:
            return run_frames[0].copy()
        return pd.concat(non_empty_frames, ignore_index=True)

    def prime_runs_cache(self, current_experiment_id: str, force_refresh: bool = False) -> None:
        """Load run summaries according to the configured cache mode."""
        current_experiment_id = str(current_experiment_id)
        if self.cache_mode == "all_expts":
            experiments_df = self.get_experiments_df()
            for experiment_id in experiments_df["experiment_id"].tolist():
                self.get_runs_df(experiment_id, force_refresh=force_refresh)
            return
        if current_experiment_id:
            self.get_runs_df(current_experiment_id, force_refresh=force_refresh)

    def find_run_id(self, experiment_id: str, run_id_or_short: str) -> str:
        """Resolve a short run id within an experiment to its full run id."""
        run_id_or_short = str(run_id_or_short)
        if len(run_id_or_short) != 5:
            return run_id_or_short
        runs_df = self.get_runs_df(str(experiment_id))
        matches = runs_df[runs_df["run_id_short"] == run_id_or_short]
        if matches.empty:
            return run_id_or_short
        return str(matches.iloc[0]["run_id"])

    def get_run_detail(self, run_id: str, force_refresh: bool = False) -> Dict[str, Any]:
        """Return cached detailed run data."""
        run_id = str(run_id)
        if force_refresh:
            self.run_details_by_id.pop(run_id, None)
            self.metric_history_by_run.pop(run_id, None)
            stale_keys = [key for key in self.artifacts_by_run if key[0] == run_id]
            for key in stale_keys:
                self.artifacts_by_run.pop(key, None)
        if run_id not in self.run_details_by_id:
            run = self.client.get_run(run_id)
            self.run_details_by_id[run_id] = _run_detail_to_dict(run)
        return self.run_details_by_id[run_id]

    def get_metric_history(
        self, run_id: str, metric_name: str, force_refresh: bool = False
    ) -> List[Dict[str, Any]]:
        """Return cached metric history for one run metric."""
        run_id = str(run_id)
        metric_name = str(metric_name)
        if force_refresh:
            self.metric_history_by_run.setdefault(run_id, {}).pop(metric_name, None)
        run_histories = self.metric_history_by_run.setdefault(run_id, {})
        if metric_name not in run_histories:
            history = self.client.get_metric_history(run_id, metric_name)
            run_histories[metric_name] = [
                {
                    "step": point.step,
                    "timestamp": point.timestamp,
                    "value": point.value,
                }
                for point in history
            ]
        return run_histories[metric_name]

    def get_artifact_tree(
        self, run_id: str, max_depth: int, collector, force_refresh: bool = False
    ) -> List[Dict[str, Any]]:
        """Return cached artifact tree for one run."""
        key = (str(run_id), int(max_depth))
        if force_refresh:
            self.artifacts_by_run.pop(key, None)
        if key not in self.artifacts_by_run:
            self.artifacts_by_run[key] = collector(
                self.tracking_uri, str(run_id), max_depth=int(max_depth)
            )
        return self.artifacts_by_run[key]


_CURRENT_SESSION: Optional[MlflowSessionCache] = None


def get_session(tracking_uri: str, view_type: Any, cache_mode: str, timeout: float):
    """Return the active MLflow cache session for the current Vim settings."""
    global _CURRENT_SESSION

    normalized_mode = (
        cache_mode if cache_mode in {"selected_expt", "all_expts"} else "selected_expt"
    )
    normalized_timeout = float(timeout)
    if _CURRENT_SESSION is None:
        _CURRENT_SESSION = MlflowSessionCache(
            tracking_uri=str(tracking_uri),
            view_type=view_type,
            cache_mode=normalized_mode,
            timeout=normalized_timeout,
        )
        return _CURRENT_SESSION

    if (
        _CURRENT_SESSION.tracking_uri != str(tracking_uri)
        or _CURRENT_SESSION.view_type != view_type
        or _CURRENT_SESSION.cache_mode != normalized_mode
    ):
        _CURRENT_SESSION = MlflowSessionCache(
            tracking_uri=str(tracking_uri),
            view_type=view_type,
            cache_mode=normalized_mode,
            timeout=normalized_timeout,
        )
        return _CURRENT_SESSION

    _CURRENT_SESSION.timeout = normalized_timeout
    return _CURRENT_SESSION


def reset_session() -> None:
    """Clear the active cache session."""
    global _CURRENT_SESSION
    _CURRENT_SESSION = None
