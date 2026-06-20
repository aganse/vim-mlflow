import ast
import importlib
import re
import sys
import types
from pathlib import Path
from typing import Dict, List

import pytest


ROOT = Path(__file__).resolve().parents[2]
PYTHON_SRC = ROOT / "python"
if str(PYTHON_SRC) not in sys.path:
    sys.path.insert(0, str(PYTHON_SRC))


class _FakeVim:
    """A very small subset of the `vim` module needed for unit tests."""

    def __init__(self) -> None:
        self.vars: Dict[str, object] = {}
        self.g: Dict[str, object] = {}
        self.s: Dict[str, object] = {}

    def eval(self, expression: str):
        if expression.startswith("g:"):
            return self.g.get(expression[2:], 0)
        if expression.startswith("s:"):
            return self.s.get(expression[2:], 0)
        get_match = re.fullmatch(
            r"get\(([gs]):,\s*'([^']+)'(?:,\s*([^\)]+))?\)", expression
        )
        if get_match:
            scope = get_match.group(1)
            name = get_match.group(2)
            raw_default = get_match.group(3)
            default = 0 if raw_default is None else self._parse_value(raw_default.strip())
            mapping = self.g if scope == "g" else self.s
            return mapping.get(name, default)

        def _replace(match: re.Match) -> str:
            scope = match.group(1)
            name = match.group(2)
            mapping = "_g" if scope == "g" else "_s"
            return f"{mapping}['{name}']"

        translated = re.sub(r"([gs]):([A-Za-z0-9_]+)", _replace, expression)
        return eval(translated, {"min": min}, {"_g": self.g, "_s": self.s})  # noqa: S307

    def command(self, command: str) -> None:
        if not command.startswith("let "):
            raise NotImplementedError("Only :let commands are supported in tests.")
        rest = command[4:].strip()
        name, raw_value = rest.split("=", 1)
        name = name.strip()
        raw_value = raw_value.strip()
        value = self._parse_value(raw_value)
        if name.startswith("g:"):
            self.g[name[2:]] = value
        elif name.startswith("s:"):
            self.s[name[2:]] = value
        else:
            raise NotImplementedError("Only g: and s: scopes are supported.")

    @staticmethod
    def _parse_value(raw: str):
        try:
            value = ast.literal_eval(raw)
        except (ValueError, SyntaxError):
            return raw
        if isinstance(value, str) and value.isdigit():
            return int(value)
        return value


@pytest.fixture
def vim_mlflow_env(monkeypatch):
    """Prepare stubbed mlflow and vim modules, then import vim_mlflow."""

    fake_vim = _FakeVim()
    vim_module = types.ModuleType("vim")
    vim_module.vars = fake_vim.vars
    vim_module.eval = fake_vim.eval
    vim_module.command = fake_vim.command
    monkeypatch.setitem(sys.modules, "vim", vim_module)

    fake_state = {
        "experiments": [],
        "runs": [],
        "runs_by_id": {},
        "metric_history": {},
        "artifacts": {},
        "calls": {
            "search_experiments": 0,
            "search_runs": 0,
            "get_run": 0,
            "get_metric_history": 0,
            "list_artifacts": 0,
        },
    }

    class FakeMlflowClient:
        def __init__(self, tracking_uri: str):
            self.tracking_uri = tracking_uri

        def search_experiments(self, view_type):
            fake_state["calls"]["search_experiments"] += 1
            return list(fake_state["experiments"])

        def search_runs(self, experiment_ids: List[str], run_view_type):
            fake_state["calls"]["search_runs"] += 1
            experiment_id_set = {str(experiment_id) for experiment_id in experiment_ids}
            return [
                run
                for run in fake_state["runs"]
                if str(run.info.experiment_id) in experiment_id_set
            ]

        def get_run(self, run_id: str):
            fake_state["calls"]["get_run"] += 1
            return fake_state["runs_by_id"][run_id]

        def get_metric_history(self, run_id: str, key: str):
            fake_state["calls"]["get_metric_history"] += 1
            return list(fake_state["metric_history"].get((run_id, key), []))

        def list_artifacts(self, run_id: str, path=None):
            fake_state["calls"]["list_artifacts"] += 1
            return list(fake_state["artifacts"].get((run_id, path), []))

    class FakeViewType:
        ACTIVE_ONLY = object()
        DELETED_ONLY = object()
        ALL = object()

    mlflow_module = types.ModuleType("mlflow")
    entities_module = types.ModuleType("mlflow.entities")
    tracking_module = types.ModuleType("mlflow.tracking")

    entities_module.ViewType = FakeViewType
    tracking_module.MlflowClient = FakeMlflowClient

    monkeypatch.setitem(sys.modules, "mlflow", mlflow_module)
    monkeypatch.setitem(sys.modules, "mlflow.entities", entities_module)
    monkeypatch.setitem(sys.modules, "mlflow.tracking", tracking_module)

    for module_name in ["vim_mlflow", "vim_mlflow_runs", "vim_mlflow_cache"]:
        if module_name in sys.modules:
            del sys.modules[module_name]
    import vim_mlflow  # noqa: F401

    module = importlib.import_module("vim_mlflow")

    return module, fake_state, fake_vim
