from tests.fixtures.mlflow import make_experiment, make_metric_history, make_run
from vim_mlflow_utils import format_run_duration


def test_format_run_duration_handles_edge_cases():
    assert format_run_duration(None) == "-"
    assert format_run_duration(float("inf")) == "infh"
    assert format_run_duration(float("nan")) == "-"
    assert format_run_duration(-1) == "-"
    assert format_run_duration(42) == "42s"
    assert format_run_duration(600) == "10m"
    assert format_run_duration(3 * 3600) == "3.0h"


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
        }
    )
    fake_vim.s.update(
        {
            "expts_first_idx": 0,
        }
    )

    lines, experiment_ids = module.getMLflowExpts("http://example.com")

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
        }
    )
    fake_vim.s.update(
        {
            "runs_first_idx": 0,
            "markruns_list": [run_1.info.run_id[:5]],
        }
    )

    lines, run_ids = module.getRunsListForExpt("http://example.com", "99")

    assert lines[0] == "2 Active Runs in expt #99:"
    assert lines[1] == "X" + "|" * 30
    assert lines[2].startswith(f">{'#'}{run_1.info.run_id[:5]}")
    assert "alice" in lines[2]
    assert "Warmup" in lines[2]
    assert lines[3].startswith(f" #{run_2.info.run_id[:5]}")
    assert "RUNNING" in lines[3]
    assert lines[-1] == "X"
    assert run_ids == [run_1.info.run_id, run_2.info.run_id]
