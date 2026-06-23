import importlib

from tests.fixtures.mlflow import make_experiment, make_metric_history, make_run
from vim_mlflow_utils import format_run_duration


def _allow_tracking_probe(monkeypatch):
    class _Response:
        def getcode(self):
            return 200

    cache_module = importlib.import_module("vim_mlflow_cache")
    monkeypatch.setattr(cache_module, "urlopen", lambda url, timeout=1.0: _Response())


def test_format_run_duration_handles_edge_cases():
    assert format_run_duration(None) == "-"
    assert format_run_duration(float("inf")) == "infh"
    assert format_run_duration(float("nan")) == "-"
    assert format_run_duration(-1) == "-"
    assert format_run_duration(42) == "42s"
    assert format_run_duration(600) == "10m"
    assert format_run_duration(3 * 3600) == "3.0h"


def test_read_artifact_display_lines_pretty_prints_json(vim_mlflow_env, tmp_path):
    module, _, _ = vim_mlflow_env

    pretty_path = tmp_path / "artifact.json"
    pretty_path.write_text('{"alpha":1,"nested":{"beta":2}}', encoding="utf-8")

    lines = module.read_artifact_display_lines("artifact.json", str(pretty_path))

    assert lines == [
        "{",
        '  "alpha": 1,',
        '  "nested": {',
        '    "beta": 2',
        "  }",
        "}",
    ]


def test_read_artifact_display_lines_falls_back_for_invalid_json(vim_mlflow_env, tmp_path):
    module, _, _ = vim_mlflow_env

    raw_path = tmp_path / "artifact.json"
    raw_path.write_text('{"alpha":', encoding="utf-8")

    lines = module.read_artifact_display_lines("artifact.json", str(raw_path))

    assert lines == ['{"alpha":']


def test_get_mlflow_experiments_formats_output(vim_mlflow_env):
    module, state, fake_vim = vim_mlflow_env

    state["experiments"] = [
        make_experiment(1, "Alpha"),
        make_experiment(2, "Beta"),
    ]

    fake_vim.g.update(
        {
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_expts_length": 8,
            "vim_mlflow_show_scrollicons": 1,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_scrollstop": "X",
            "vim_mlflow_icon_scrollup": "^",
            "vim_mlflow_icon_scrolldown": "v",
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "selected_expt",
        }
    )
    fake_vim.s.update(
        {
            "expts_first_idx": 0,
        }
    )

    lines, experiment_ids = module.getMLflowExpts(module._get_session("http://example.com"))

    assert lines[0] == "2 Active Experiments:"
    assert lines[1] == "X" + "|" * 30
    assert lines[2] == "#2: Beta"
    assert lines[3] == "#1: Alpha"
    assert lines[-1] == "X"
    assert experiment_ids == ["2", "1"]


def test_get_runs_list_formats_columns(vim_mlflow_env):
    module, state, fake_vim = vim_mlflow_env

    start_time = 1_700_000_000_000
    run_1 = make_run(
        "run-aaa111",
        start_time_ms=start_time + 5_000,
        end_time_ms=start_time + 65_000,
        user_id="alice",
        run_name="Warmup",
    )
    run_2 = make_run(
        "run-bbb222",
        start_time_ms=start_time,
        end_time_ms=None,
        status="RUNNING",
        user_id="bob",
        run_name="Long job",
    )

    state["runs"] = [run_1, run_2]
    state["runs_by_id"] = {run_1.info.run_id: run_1, run_2.info.run_id: run_2}
    state["metric_history"][(run_1.info.run_id, "loss")] = make_metric_history([0.4, 0.2])

    fake_vim.g.update(
        {
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_runs_length": 8,
            "vim_mlflow_show_scrollicons": 1,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_scrollstop": "X",
            "vim_mlflow_icon_scrollup": "^",
            "vim_mlflow_icon_scrolldown": "v",
            "vim_mlflow_icon_markrun": ">",
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "selected_expt",
        }
    )
    fake_vim.s.update(
        {
            "runs_first_idx": 0,
            "markruns_list": [run_1.info.run_id[:5]],
        }
    )

    lines, run_ids = module.getRunsListForExpt(module._get_session("http://example.com"), "99")

    assert lines[0] == "2 Active Runs in expt #99:"
    assert lines[1] == "X" + "|" * 30
    assert lines[2].startswith(f">{'#'}{run_1.info.run_id[:5]}")
    assert "alice" in lines[2]
    assert "Warmup" in lines[2]
    assert lines[3].startswith(f" #{run_2.info.run_id[:5]}")
    assert "RUNNING" in lines[3]
    assert lines[-1] == "X"
    assert run_ids == [run_1.info.run_id, run_2.info.run_id]


def test_main_page_reuses_cached_queries(vim_mlflow_env, monkeypatch):
    module, state, fake_vim = vim_mlflow_env
    _allow_tracking_probe(monkeypatch)

    run = make_run(
        "run-aaa111",
        1_700_000_005_000,
        1_700_000_065_000,
        experiment_id="99",
        user_id="alice",
        run_name="Warmup",
        params={"lr": "0.1"},
        metrics={"loss": 0.2},
    )
    state["experiments"] = [make_experiment(99, "Alpha")]
    state["runs"] = [run]
    state["runs_by_id"] = {run.info.run_id: run}
    state["metric_history"][(run.info.run_id, "loss")] = make_metric_history([0.4, 0.2])

    fake_vim.g.update(
        {
            "vim_mlflow_version": "dev",
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "selected_expt",
            "vim_mlflow_expts_length": 8,
            "vim_mlflow_runs_length": 8,
            "vim_mlflow_show_scrollicons": 1,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_scrollstop": "X",
            "vim_mlflow_icon_scrollup": "^",
            "vim_mlflow_icon_scrolldown": "v",
            "vim_mlflow_icon_markrun": ">",
            "vim_mlflow_section_order": ["params", "metrics", "tags", "artifacts"],
            "vim_mlflow_artifacts_max_depth": 3,
        }
    )
    fake_vim.s.update(
        {
            "current_exptid": "",
            "current_runid": "",
            "expts_first_idx": 0,
            "runs_first_idx": 0,
            "params_are_showing": 1,
            "metrics_are_showing": 1,
            "tags_are_showing": 1,
            "artifacts_are_showing": 0,
            "markruns_list": [],
        }
    )

    first = module.getMainPageMLflow("http://example.com", force_refresh=True)
    second = module.getMainPageMLflow("http://example.com")

    assert first == second
    assert state["calls"]["search_experiments"] == 1
    assert state["calls"]["search_runs"] == 1
    assert state["calls"]["get_run"] == 1
    assert state["calls"]["get_metric_history"] == 1


def test_main_page_force_refresh_invalidates_cache(vim_mlflow_env, monkeypatch):
    module, state, fake_vim = vim_mlflow_env
    _allow_tracking_probe(monkeypatch)

    run = make_run(
        "run-aaa111",
        1_700_000_005_000,
        1_700_000_065_000,
        experiment_id="99",
        metrics={"loss": 0.2},
    )
    state["experiments"] = [make_experiment(99, "Alpha")]
    state["runs"] = [run]
    state["runs_by_id"] = {run.info.run_id: run}
    state["metric_history"][(run.info.run_id, "loss")] = make_metric_history([0.4, 0.2])

    fake_vim.g.update(
        {
            "vim_mlflow_version": "dev",
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "selected_expt",
            "vim_mlflow_expts_length": 8,
            "vim_mlflow_runs_length": 8,
            "vim_mlflow_show_scrollicons": 0,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_markrun": ">",
            "vim_mlflow_section_order": ["metrics"],
            "vim_mlflow_artifacts_max_depth": 3,
        }
    )
    fake_vim.s.update(
        {
            "current_exptid": "99",
            "current_runid": run.info.run_id,
            "expts_first_idx": 0,
            "runs_first_idx": 0,
            "params_are_showing": 0,
            "metrics_are_showing": 1,
            "tags_are_showing": 0,
            "artifacts_are_showing": 0,
            "markruns_list": [],
        }
    )

    module.getMainPageMLflow("http://example.com", force_refresh=True)
    module.getMainPageMLflow("http://example.com", force_refresh=True)

    assert state["calls"]["search_experiments"] == 2
    assert state["calls"]["search_runs"] == 2
    assert state["calls"]["get_run"] == 2
    assert state["calls"]["get_metric_history"] == 2


def test_all_expts_mode_primes_run_summaries_for_each_experiment(vim_mlflow_env, monkeypatch):
    module, state, fake_vim = vim_mlflow_env
    _allow_tracking_probe(monkeypatch)

    run_1 = make_run("run-aaa111", 1_700_000_005_000, 1_700_000_065_000, experiment_id="99")
    run_2 = make_run("run-bbb222", 1_700_000_010_000, 1_700_000_070_000, experiment_id="100")
    state["experiments"] = [make_experiment(99, "Alpha"), make_experiment(100, "Beta")]
    state["runs"] = [run_1, run_2]
    state["runs_by_id"] = {run_1.info.run_id: run_1, run_2.info.run_id: run_2}

    fake_vim.g.update(
        {
            "vim_mlflow_version": "dev",
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "all_expts",
            "vim_mlflow_expts_length": 8,
            "vim_mlflow_runs_length": 8,
            "vim_mlflow_show_scrollicons": 0,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_markrun": ">",
            "vim_mlflow_section_order": ["params"],
            "vim_mlflow_artifacts_max_depth": 3,
        }
    )
    fake_vim.s.update(
        {
            "current_exptid": "99",
            "current_runid": "",
            "expts_first_idx": 0,
            "runs_first_idx": 0,
            "params_are_showing": 0,
            "metrics_are_showing": 0,
            "tags_are_showing": 0,
            "artifacts_are_showing": 0,
            "markruns_list": [],
        }
    )

    module.getMainPageMLflow("http://example.com", force_refresh=True)

    assert state["calls"]["search_experiments"] == 1
    assert state["calls"]["search_runs"] == 2


def test_runs_page_uses_cached_run_details(vim_mlflow_env, monkeypatch):
    module, state, fake_vim = vim_mlflow_env
    _allow_tracking_probe(monkeypatch)

    run = make_run(
        "run-aaa111",
        1_700_000_005_000,
        1_700_000_065_000,
        experiment_id="99",
        user_id="alice",
        run_name="Warmup",
        params={"lr": "0.1"},
        metrics={"loss": 0.2},
    )
    state["experiments"] = [make_experiment(99, "Alpha")]
    state["runs"] = [run]
    state["runs_by_id"] = {run.info.run_id: run}
    state["metric_history"][(run.info.run_id, "loss")] = make_metric_history([0.4, 0.2])

    fake_vim.g.update(
        {
            "vim_mlflow_version": "dev",
            "vim_mlflow_viewtype": 1,
            "vim_mlflow_timeout": 0.5,
            "vim_mlflow_runs_cache_mode": "selected_expt",
            "vim_mlflow_expts_length": 8,
            "vim_mlflow_runs_length": 8,
            "vim_mlflow_show_scrollicons": 0,
            "vim_mlflow_icon_vdivider": "|",
            "vim_mlflow_icon_markrun": ">",
            "vim_mlflow_section_order": ["params", "metrics"],
            "vim_mlflow_artifacts_max_depth": 3,
        }
    )
    fake_vim.s.update(
        {
            "current_exptid": "99",
            "current_runid": run.info.run_id,
            "expts_first_idx": 0,
            "runs_first_idx": 0,
            "params_are_showing": 1,
            "metrics_are_showing": 1,
            "tags_are_showing": 0,
            "artifacts_are_showing": 0,
            "markruns_list": [run.info.run_id[:5]],
            "markruns_exptids": ["99"],
            "runs_tags_are_showing": 1,
            "runs_params_are_showing": 1,
            "runs_metrics_are_showing": 1,
            "debuglines": [],
        }
    )

    module.getMainPageMLflow("http://example.com", force_refresh=True)
    assert state["calls"]["get_run"] == 1

    runs_module = importlib.import_module("vim_mlflow_runs")
    out = runs_module.getRunsPageMLflow("http://example.com")

    assert any("#99" in line for line in out)
    assert state["calls"]["get_run"] == 1
