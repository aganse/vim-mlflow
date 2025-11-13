from datetime import datetime
from urllib.request import urlopen, Request

import mlflow
from mlflow.entities import ViewType
from mlflow.tracking import MlflowClient
# import pandas as pd
import vim
import warnings

#warnings.simplefilter(action='ignore', category=FutureWarning)


VIEWTYPE_MAP = {
    1: ViewType.ACTIVE_ONLY,
    2: ViewType.DELETED_ONLY,
    3: ViewType.ALL,
}

VIEWTYPE_LABELS = {
    1: "Active",
    2: "Deleted",
    3: "Total",
}


def getMLflowExpts(mlflow_tracking_uri):
    try:
        lifecycles = {"active": "A", "deleted": "D"}
        client = MlflowClient(tracking_uri=mlflow_tracking_uri)
        view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
        view_type = VIEWTYPE_MAP.get(view_idx, ViewType.ACTIVE_ONLY)
        expts = client.search_experiments(view_type=view_type)

        output_lines = []
        num_expts_viewtype = len(expts)
        vim.command("let s:num_expts='" + str(num_expts_viewtype) + "'")
        output_lines.append(f"{vim.eval('s:num_expts')} {VIEWTYPE_LABELS.get(view_idx, VIEWTYPE_LABELS[1])} Experiments:")
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:expts_first_idx")) == 0:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollup")
        else:
            scrollicon = ""
        output_lines.append(scrollicon + vim.eval("g:vim_mlflow_icon_vdivider")*30)
        expts = sorted(expts, key=lambda e: int(e.experiment_id), reverse=True)
        beginexpt_idx = int(vim.eval("s:expts_first_idx"))
        endexpt_idx = int(vim.eval("s:expts_first_idx"))+int(vim.eval("g:vim_mlflow_expts_length"))
        for expt in expts[beginexpt_idx: endexpt_idx]:
            if view_type == ViewType.ALL:
                stage_letter = lifecycles.get(expt.lifecycle_stage, expt.lifecycle_stage[:1].upper())
                output_lines.append(f"#{expt.experiment_id}: {stage_letter} {expt.name}")
            else:
                output_lines.append(f"#{expt.experiment_id}: {expt.name}")
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:expts_first_idx")) == \
               int(vim.eval("s:num_expts-min([g:vim_mlflow_expts_length, s:num_expts])")):
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrolldown")
        else:
            scrollicon = ""
        output_lines.append(scrollicon)
        return output_lines, [expt.experiment_id for expt in expts]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getRunsListForExpt(mlflow_tracking_uri, current_exptid):
    try:
        lifecycles = {"active": "A", "deleted": "D"}
        client = MlflowClient(tracking_uri=mlflow_tracking_uri)
        view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
        view_type = VIEWTYPE_MAP.get(view_idx, ViewType.ACTIVE_ONLY)
        runs = client.search_runs([str(current_exptid)], run_view_type=view_type)

        output_lines = []
        num_runs_viewtype = len(runs)
        vim.command("let s:num_runs='" + str(num_runs_viewtype) + "'")
        output_lines.append(f"{vim.eval('s:num_runs')} {VIEWTYPE_LABELS.get(view_idx, VIEWTYPE_LABELS[1])} Runs in expt #{current_exptid}:")
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:runs_first_idx")) == 0:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollup")
        else:
            scrollicon = ""
        output_lines.append(scrollicon + vim.eval("g:vim_mlflow_icon_vdivider")*30)
        runs = sorted(runs, key=lambda r: r.info.start_time, reverse=True)
        beginrun_idx = int(vim.eval("s:runs_first_idx"))
        endrun_idx = int(vim.eval("s:runs_first_idx"))+int(vim.eval("g:vim_mlflow_runs_length"))
        for run in runs[beginrun_idx: endrun_idx]:
            if run.info.start_time:
                st = datetime.utcfromtimestamp(run.info.start_time/1e3).strftime("%Y-%m-%d %H:%M:%S")
            else:
                st = "N/A"
            mark = " "
            if run.info.run_id[:5] in vim.eval("s:markruns_list"):
                mark = vim.eval("g:vim_mlflow_icon_markrun")
            runtags = run.data.tags
            runname = run.info.run_name if "mlflow.runName" in runtags else ""
            if view_type == ViewType.ALL:
                stage_letter = lifecycles.get(run.info.lifecycle_stage, run.info.lifecycle_stage[:1].upper())
                output_lines.append(f"{mark}#{run.info.run_id[:5]}: {stage_letter} {st}  {runname}")
            else:
                output_lines.append(f"{mark}#{run.info.run_id[:5]}: {st}  {runname}")
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:runs_first_idx")) == \
               int(vim.eval("s:num_runs-min([g:vim_mlflow_runs_length, s:num_runs])")):
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrolldown")
        else:
            scrollicon = ""
        output_lines.append(scrollicon)
        return output_lines, [run.info.run_id for run in runs]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getMetricsListForRun(mlflow_tracking_uri, current_runid):
    try:
        client = MlflowClient(tracking_uri=mlflow_tracking_uri)
        run = client.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Metrics in run #{current_runid[:5]}:")
        output_lines.append(vim.eval("g:vim_mlflow_icon_vdivider")*30)
        for k,v in run.data.metrics.items():
            output_lines.append(f"  {k}: {v:.4g}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getParamsListForRun(mlflow_tracking_uri, current_runid):
    try:
        client = MlflowClient(tracking_uri=mlflow_tracking_uri)
        run = client.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Params in run #{current_runid[:5]}:")
        output_lines.append(vim.eval("g:vim_mlflow_icon_vdivider")*30)
        for k,v in run.data.params.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getTagsListForRun(mlflow_tracking_uri, current_runid):
    try:
        client = MlflowClient(tracking_uri=mlflow_tracking_uri)
        run = client.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Tags in run #{current_runid[:5]}:")
        output_lines.append(vim.eval("g:vim_mlflow_icon_vdivider")*30)
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
