import re
from urllib.request import urlopen

from mlflow.entities import ViewType
import pandas as pd
import vim


from vim_mlflow_cache import get_session
from vim_mlflow_utils import format_run_duration

VIEWTYPE_MAP = {
    1: ViewType.ACTIVE_ONLY,
    2: ViewType.DELETED_ONLY,
    3: ViewType.ALL,
}


def _vim_flag(expression):
    """Interpret a Vimscript boolean-like value as a Python bool."""
    return str(vim.eval(expression)) == "1"


def getRunsPageMLflow(mlflow_tracking_uri):
    """Render the marked-runs comparison buffer from cached run data."""
    out = []
    out.append("Vim-MLflow Marked Runs")
    out.append("\" Press ? for help")
    for dline in vim.eval("s:debuglines"):
        out.append('" '+dline)
    out.append("")
    if not vim.eval("s:markruns_list"):
        # no marked runs in list so nothing to do
        out.append("")
        out.append("No marked runs.")
        return out

    view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
    view_type = VIEWTYPE_MAP.get(view_idx, ViewType.ACTIVE_ONLY)
    cache_mode = vim.eval("get(g:, 'vim_mlflow_runs_cache_mode', 'selected_expt')")
    if cache_mode not in {"selected_expt", "all_expts"}:
        cache_mode = "selected_expt"
    session = get_session(
        mlflow_tracking_uri,
        view_type,
        cache_mode,
        float(vim.eval("g:vim_mlflow_timeout")),
    )

    if session.ensure_available():

        # Find full runids for the short-runids in s:markruns_list using cached summaries.
        exptids_to_scan = []
        current_exptid = str(vim.eval("s:current_exptid"))
        if current_exptid != "":
            exptids_to_scan.append(current_exptid)
        for exptid in vim.eval("s:markruns_exptids"):
            if str(exptid) not in exptids_to_scan:
                exptids_to_scan.append(str(exptid))

        runs_by_short = {}
        for exptid in exptids_to_scan:
            if exptid == "":
                continue
            runs_df = session.get_runs_df(exptid)
            for _, run in runs_df.iterrows():
                runs_by_short[(exptid, run["run_id_short"])] = {
                    "run_id": run["run_id"],
                    "summary": run.to_dict(),
                }

        fullmarkrunids = []
        summaries_by_run = {}
        markruns_exptids = vim.eval("s:markruns_exptids") or []
        for idx, runid5 in enumerate(vim.eval("s:markruns_list")):
            exptid = ""
            if idx < len(markruns_exptids):
                exptid = str(markruns_exptids[idx])
            key = (exptid, runid5)
            if key not in runs_by_short and current_exptid:
                key = (current_exptid, runid5)
            if key in runs_by_short:
                full_run_id = runs_by_short[key]["run_id"]
                fullmarkrunids.append(full_run_id)
                summaries_by_run[full_run_id] = runs_by_short[key]["summary"]

        # Loop over marked full-runids to get their complete info for display.
        runsforpd = []
        for runid in fullmarkrunids:
            detail = session.get_run_detail(runid)
            rundict = dict(detail["info"])
            summary = summaries_by_run.get(runid, {})
            if summary:
                rundict.setdefault("start_time", summary.get("start_time_ms"))
                rundict.setdefault("end_time", summary.get("end_time_ms"))
                rundict.setdefault("status", summary.get("status"))
                rundict.setdefault("lifecycle_stage", summary.get("lifecycle_stage"))
                rundict.setdefault("experiment_id", summary.get("experiment_id"))
                rundict.setdefault("run_id", summary.get("run_id"))
                rundict.setdefault("user_id", summary.get("user"))
            if _vim_flag("s:runs_tags_are_showing"):
                rundict.update(detail["data"]["tags"])
            if _vim_flag("s:runs_params_are_showing"):
                rundict.update(detail["data"]["params"])
            if _vim_flag("s:runs_metrics_are_showing"):
                rundict.update(detail["data"]["metrics"])
            runsforpd.append(rundict)
        runsdf = pd.DataFrame(runsforpd)
        if runsdf.empty:
            out.append("")
            out.append("No marked runs.")
            return out

        # Process dataframe regarding collapsed/hidden/shortened columns

        # Drop, rename, and reorder certain key columns to match mlflow webpage
        runsdf = runsdf.rename(
            columns={
                "experiment_id": "expt_id",
                "lifecycle_stage": "lifecycle",
                "mlflow.user": "user",
                "mlflow.source.name": "source.name",
                "mlflow.source.type": "source.type",
                "mlflow.source.git.commit": "git.commit",
                "mlflow.source.git.repoURL": "git.repoURL",
                "mlflow.project.backend": "backend",
                "mlflow.project.entryPoint": "entryPoint",
                "mlflow.project.env": "env",
                }
            )
        # duplicated cols:
        runsdf = runsdf.drop(columns=["run_uuid", "user_id", "mlflow.gitRepoURL"], errors="ignore")
        # huge columns:
        runsdf = runsdf.drop(columns=["mlflow.log-model.history", "artifact_uri"], errors="ignore")

        if "start_time" in runsdf.columns:
            runsdf.insert(0, "start_time", runsdf.pop("start_time"))
        if "end_time" in runsdf.columns:
            runsdf.insert(0, "run_id", runsdf.pop("run_id"))
        if "expt_id" in runsdf.columns:
            runsdf.insert(0, "expt_id", runsdf.pop("expt_id"))

        # Shorten specified columns
        runsdf["run_id"] = runsdf["run_id"].apply(lambda x: x[:5])  # run_id always in run results!
        if "source.name" in runsdf.columns:
            runsdf["source.name"] = runsdf["source.name"].apply(lambda x: x.split("/")[-1])
        if "git.commit" in runsdf.columns:
            runsdf["git.commit"] = runsdf["git.commit"].apply(lambda x: x[:6])

        # Some final formatting
        runsdf["expt_id"] = runsdf["expt_id"].apply(lambda x: "#"+x)
        runsdf["run_id"] = runsdf["run_id"].apply(lambda x: "#"+x)
        if "start_time" in runsdf.columns:
            runsdf["start_time"] = pd.to_numeric(runsdf["start_time"], errors="coerce")
            runsdf["start_time"] = pd.to_datetime(runsdf["start_time"], unit="ms", errors="coerce")
        if "end_time" in runsdf.columns:
            runsdf["end_time"] = pd.to_numeric(runsdf["end_time"], errors="coerce")
            runsdf["end_time"] = pd.to_datetime(runsdf["end_time"], unit="ms", errors="coerce")
        insert_idx = len(runsdf.columns)
        if "status" in runsdf.columns:
            insert_idx = runsdf.columns.get_loc("status") + 1
        elif "user" in runsdf.columns:
            insert_idx = runsdf.columns.get_loc("user")
        if "start_time" in runsdf.columns and "end_time" in runsdf.columns:
            timedeltas = runsdf["end_time"] - runsdf["start_time"]
            duration_col = timedeltas.apply(
                lambda td: format_run_duration(td.total_seconds() if not pd.isna(td) else None)
            )
        else:
            duration_col = pd.Series("-", index=runsdf.index)
        runsdf.insert(insert_idx, "duration", duration_col)
        runsdf = runsdf.sort_values(["expt_id", "start_time"], ascending=False)

        # Collapse specified columns
        colnames = runsdf.columns.values
        collapsedcols_list = vim.eval("s:collapsedcols_list")
        if not isinstance(collapsedcols_list, list):
            collapsedcols_list = []
        for colidstr in collapsedcols_list:
            col_idx = int(colidstr)
            colname = runsdf.columns[col_idx]
            runsdf[colname] = runsdf[colname].astype(str)
            runsdf[colname] = ":"
            colnames[col_idx] = ":"
        runsdf.columns = colnames

        # Hide (remove) specified columns
        hiddencols_list = vim.eval("s:hiddencols_list")
        if not isinstance(hiddencols_list, list):
            hiddencols_list = []
        cols2keep = [
            int(col)
            for col in range(runsdf.shape[1])
            if str(col) not in hiddencols_list
        ]
        runsdf = runsdf.iloc[:, cols2keep]

        # Output dataframe
        lines = runsdf.to_string(index=False, justify="center").split('\n')
        for i, line in enumerate(lines):
            out.append(line)
            if i == 0:
                out.append(make_headerline(lines, vim.eval("g:vim_mlflow_icon_vdivider")))

        # Retaining these lines while still debugging occasional column-hiding bug:
        # out.append(f"nredcols:{vim.eval('s:numreducedcols')}")
        # out.append(f"cols2keep:{cols2keep}")
        # out.append(f"hidcols:{vim.eval('s:hiddencols_list')}")
        # out.append(f"clpcols:{vim.eval('s:collapsedcols_list')}")

    else:
        out.append("Could not connect to mlflow_tracking_uri")
        out.append(mlflow_tracking_uri)
        out.append(f"within the g:vim_mlflow_timeout={float(vim.eval('g:vim_mlflow_timeout')):.2f}")
        out.append("Are you sure that's the right URI?")
    return out


def make_headerline(lines, divchar):
    """Make the line under column headers based on char locations in columns"""
    a = re.sub('[^ ]', divchar, lines[0])
    for i in range(len(lines)-1):
        b = re.sub('[^ ]', divchar, lines[i+1])
        a = ''.join(map(lambda x: divchar if x[0] == divchar or x[1] == divchar else ' ',
                        zip(a, b)))
    return a


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
        if urlopen(url, timeout=timeout).getcode() == 200:
            out = True
    except Exception as exc:  # fallback if you tr
        print("Unexpected failure: %s", exc)
        out = False

    return out
