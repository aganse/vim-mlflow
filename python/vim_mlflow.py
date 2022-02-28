from datetime import datetime
from urllib.request import urlopen, Request

import mlflow
from mlflow.entities import ViewType, LifecycleStage
# import pandas as pd
import vim


def getMLflowExpts(mlflow_tracking_uri):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        lifecycles = {"active": "A", "deleted": "D"}
        viewtype = [" Active", " Deleted", ""]

        expts = mlflow.list_experiments()

        output_lines = []
        num_expts_viewtype = len([expt for expt in expts if LifecycleStage.matches_view_type(int(vim.eval("g:vim_mlflow_viewtype")), expt.lifecycle_stage)])
        vim.command("let s:num_expts='" + str(num_expts_viewtype) + "'")
        if int(vim.eval('g:vim_mlflow_viewtype'))==ViewType.ALL:
            output_lines.append(f"{vim.eval('s:num_expts')} Experiments:")
        else:
            output_lines.append(f"{vim.eval('s:num_expts')}{viewtype[int(vim.eval('g:vim_mlflow_viewtype'))-1]} Experiments:")
        output_lines.append("------------------------------")
        expts = sorted(expts, key=lambda e: int(e.experiment_id))
        beginexpt_idx = int(vim.eval("s:expts_first_idx"))
        endexpt_idx = int(vim.eval("s:expts_first_idx"))+int(vim.eval("g:vim_mlflow_expts_length"))
        for expt in expts[beginexpt_idx: endexpt_idx]:
            if LifecycleStage.matches_view_type(int(vim.eval("g:vim_mlflow_viewtype")), expt.lifecycle_stage):
                if int(vim.eval('g:vim_mlflow_viewtype'))==ViewType.ALL:
                    output_lines.append(f"#{expt.experiment_id}: {lifecycles[expt.lifecycle_stage]} {expt.name}")
                else:
                    output_lines.append(f"#{expt.experiment_id}: {expt.name}")
        output_lines.append("")
        return output_lines, [expt.experiment_id for expt in expts]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getRunsListForExpt(mlflow_tracking_uri, current_exptid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        lifecycles = {"active": "A", "deleted": "D"}
        viewtype = [" Active", " Deleted", ""]

        # viewtypes = [ViewType.ACTIVE_ONLY, ViewType.DELETED_ONLY, ViewType.ALL]
        # viewtype = viewtypes[vim.eval("g:vim_mlflow_viewtype")]
        runs = mlflow.list_run_infos(current_exptid, run_view_type=int(vim.eval("g:vim_mlflow_viewtype")))

        output_lines = []
        num_runs_viewtype = len([run for run in runs if LifecycleStage.matches_view_type(int(vim.eval("g:vim_mlflow_viewtype")), run.lifecycle_stage)])
        vim.command("let s:num_runs='" + str(num_runs_viewtype) + "'")
        # output_lines.append(f"{vim.eval('s:num_runs')} Runs in expt #{current_exptid}:")
        if int(vim.eval('g:vim_mlflow_viewtype'))==ViewType.ALL:
            output_lines.append(f"{vim.eval('s:num_runs')} Runs in expt #{current_exptid}:")
        else:
            output_lines.append(f"{vim.eval('s:num_runs')}{viewtype[int(vim.eval('g:vim_mlflow_viewtype'))-1]} Runs in expt #{current_exptid}:")
        output_lines.append("------------------------------")
        runs = sorted(runs, key=lambda r: r.start_time)
        beginrun_idx = int(vim.eval("s:runs_first_idx"))
        endrun_idx = int(vim.eval("s:runs_first_idx"))+int(vim.eval("g:vim_mlflow_runs_length"))
        for run in runs[beginrun_idx: endrun_idx]:
            st = datetime.utcfromtimestamp(run.start_time/1e3).strftime('%Y-%m-%d %H:%M:%S')
            if LifecycleStage.matches_view_type(int(vim.eval("g:vim_mlflow_viewtype")), run.lifecycle_stage):
                if int(vim.eval('g:vim_mlflow_viewtype'))==ViewType.ALL:
                    output_lines.append(f"#{run.run_id[:5]}: {lifecycles[run.lifecycle_stage]} {st}")
                else:
                    output_lines.append(f"#{run.run_id[:5]}: {st}")
        output_lines.append("")
        return output_lines, [run.run_id for run in runs]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getMetricsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Metrics in run #{current_runid[:5]}:")
        output_lines.append("------------------------------")
        for k,v in run.data.metrics.items():
            output_lines.append(f"  {k}: {v:.4g}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getParamsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Params in run #{current_runid[:5]}:")
        output_lines.append("------------------------------")
        for k,v in run.data.params.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getTagsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Tags in run #{current_runid[:5]}:")
        output_lines.append("------------------------------")
        for k,v in run.data.tags.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getMainPageMLflow(mlflow_tracking_uri):

    out = []
    out.append("Vim-MLflow")
    out.append("\" Press ? for help")
    out.append("")
    out.append("")
    if verifyTrackingUrl(mlflow_tracking_uri, timeout=float(vim.eval("g:vim_mlflow_timeout"))):
        text, exptids = getMLflowExpts(mlflow_tracking_uri)
        out.extend(text)
        out.append("")
        if vim.eval("s:current_exptid") == "":
            vim.command("let s:current_exptid='" + exptids[0] + "'")
        text, runids = getRunsListForExpt(mlflow_tracking_uri, vim.eval("s:current_exptid"))
        out.extend(text)
        out.append("")
        if runids:
            if vim.eval("s:current_runid") == "":
                vim.command("let s:current_runid='" + runids[0] + "'")
            elif len(vim.eval("s:current_runid"))==5:
                fullrunid = [runid for runid in runids if runid[:5]==vim.eval("s:current_runid")][0]
                vim.command("let s:current_runid='" + fullrunid + "'")
            if vim.eval("s:params_are_showing")=="1":
              out.extend(getParamsListForRun(mlflow_tracking_uri, vim.eval("s:current_runid")))
            if vim.eval("s:metrics_are_showing")=="1":
              out.extend(getMetricsListForRun(mlflow_tracking_uri, vim.eval("s:current_runid")))
            if vim.eval("s:tags_are_showing")=="1":
              out.extend(getTagsListForRun(mlflow_tracking_uri, vim.eval("s:current_runid")))
    else:
        out.append("Could not connect to mlflow_tracking_uri")
        out.append(mlflow_tracking_uri)
        out.append(f"within the g:vim_mlflow_timeout={float(vim.eval('g:vim_mlflow_timeout')):.2f}")
        out.append("Are you sure that's the right URI?")
    return out


def verifyTrackingUrl(url, timeout=1.0):
    """Check that the MLflow URL is running/accessible.  However this is a
    special-case usage, only valid if the mlflow_tracking_uri is an http
    URL.  Ultimately the point is really to see if the mlflow tracking server
    is responding, much faster than the harwired 1-minute timeout built-in
    to the MLflow python API.  This works for me for now, but we want something
    more general in future.
    """

    if not url.startswith("http"):
        raise RuntimeError("Incorrect and possibly insecure protocol in url")

    try:
        if urlopen(url, timeout=timeout).getcode()==200:
            out = True
    except:
        out = False

    return out
