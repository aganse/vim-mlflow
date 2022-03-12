from datetime import datetime
from urllib.request import urlopen, Request

import mlflow
from mlflow.entities import ViewType, LifecycleStage
import pandas as pd
import vim


def getRunsPageMLflow(mlflow_tracking_uri):
    out = []
    out.append("Vim-MLflow Marked Runs")
    out.append("\" Press ? for help")
    out.append("")
    if verifyTrackingUrl(mlflow_tracking_uri, timeout=float(vim.eval("g:vim_mlflow_timeout"))):

        if vim.eval("s:current_exptid") != "":
            runinfos = mlflow.list_run_infos(vim.eval("s:current_exptid"), run_view_type=int(vim.eval("g:vim_mlflow_viewtype")))

        # Find full runids for the short-runids in s:markruns_list
        fullmarkrunids = []
        for run in runinfos:
            if run.run_id[:5] in vim.eval("s:markruns_list"):
                fullmarkrunids.append(run.run_id)
        # if markruns_list included runs from other expts they won't be in fullmarkrunidss_list yet
        # but i want this - need to add further mechanism here to populate fullmarkrunidss_list
        # with the runs in markruns_list from other expts

        # Loop over marked full-runids to get their complete info for display:
        runsforpd = []
        for runid in fullmarkrunids:
            mldict = mlflow.get_run(runid).to_dictionary()
            rundict = mldict["info"]
            rundict.update(mldict["data"]["tags"])
            rundict.update(mldict["data"]["metrics"])
            rundict.update(mldict["data"]["params"])
            runsforpd.append(rundict)
        runsdf = pd.DataFrame(runsforpd)

        # Process dataframe regarding visible/hidden/shortened columns

        # Drop, rename, and reorder certain key columns to match mlflow webpage
        runsdf = runsdf.rename(columns={"experiment_id": "expt_id", "mlflow.user": "user", "mlflow.source.name": "source.name", "mlflow.source.type": "source.type", "mlflow.source.git.commit": "git.commit", "mlflow.runName": "runName", "lifecycle_stage": "lifecycle", "mlflow.project.backend": "backend", "mlflow.project.entryPoint": "entryPoint", "mlflow.source.git.repoURL": "git.repoURL", "mlflow.project.env": "env"})
        runsdf = runsdf.drop(columns=["run_uuid", "user_id", "mlflow.gitRepoURL"], errors="ignore")  # duplicate cols
        runsdf = runsdf.drop(columns=["mlflow.log-model.history", "artifact_uri"], errors="ignore")  # huge columns
        if "runName" in runsdf.columns:
            runsdf.insert(0, "runName", runsdf.pop("runName"))
        if "start_time" in runsdf.columns:
            runsdf.insert(0, "start_time", runsdf.pop("start_time"))
        if "end_time" in runsdf.columns:
            runsdf.insert(0, "run_id", runsdf.pop("run_id"))
        if "expt_id" in runsdf.columns:
            runsdf.insert(0, "expt_id", runsdf.pop("expt_id"))

        # Shorten specified columns
        runsdf["source.name"] = runsdf["source.name"].apply(lambda x: x.split("/")[-1])
        runsdf["git.commit"] = runsdf["git.commit"].apply(lambda x: x[:6])
        runsdf["run_id"] = runsdf["run_id"].apply(lambda x: x[:5])
        if "runName" in runsdf.columns:
            runsdf["runName"] = runsdf["runName"].apply(lambda x: x[:20])

        # Hide specified columns
        colnames = runsdf.columns.values
        for colidstr in vim.eval("s:hiddencols_list"):
            runsdf.iloc[:, int(colidstr)] = ":"
            colnames[int(colidstr)] = ":"
        runsdf.columns = colnames

        # Output dataframe
        #runsdf["start_time"] = runsdf["start_time"].apply(lambda x: round(x/1.0e9))
        #runsdf["end_time"] = runsdf["end_time"].apply(lambda x: round(x/1.0e9))
        #runsdf["start_time"] = pd.to_datetime(runsdf["start_time"], format="%Y-%m-%d_%H:%M:%S")
        #runsdf["end_time"] = pd.to_datetime(runsdf["end_time"], format="%Y-%m-%d_%H:%M:%S")
        lines = runsdf.to_string(index=False, justify="center").split('\n')
        for line in lines:
            out.append(line)

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
