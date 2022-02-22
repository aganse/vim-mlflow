from datetime import datetime
import mlflow
from mlflow.entities import ViewType
from mlflow.tracking import MlflowClient
import vim


def getMLflowExpts(mlflow_tracking_uri):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        # print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

        expts = mlflow.list_experiments()

        output_lines = []
        output_lines.append("Experiments:")
        output_lines.append("------------")
        for expt in expts:
            output_lines.append(f"#{expt.experiment_id}:  {expt.name}")
        output_lines.append("")
        return output_lines, [expt.experiment_id for expt in expts]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getRunsListForExpt(mlflow_tracking_uri, current_exptid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        # print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

        runs = mlflow.list_run_infos(current_exptid, run_view_type=ViewType.ACTIVE_ONLY)  # ACTIVE_ONLY, DELETED_ONLY, or ALL

        output_lines = []
        output_lines.append(f"Runs in expt #{current_exptid}:")
        output_lines.append("------------------")
        for run in runs:
            st = datetime.utcfromtimestamp(run.start_time/1e3).strftime('%Y-%m-%d %H:%M:%S')
            #current_runid = run.run_id
            output_lines.append(f"#{run.run_id[:5]}: {st}")
        output_lines.append("")
        return output_lines, [run.run_id for run in runs]

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getMetricsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        # print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Metrics in run #{current_runid[:5]}:")
        output_lines.append("-----------------------")
        for k,v in run.data.metrics.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getParamsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        # print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Params in run #{current_runid[:5]}:")
        output_lines.append("-----------------------")
        for k,v in run.data.params.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getTagsListForRun(mlflow_tracking_uri, current_runid):
    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        # print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

        run = mlflow.get_run(current_runid)

        output_lines = []
        output_lines.append(f"Tags in run #{current_runid[:5]}:")
        output_lines.append("-----------------------")
        for k,v in run.data.tags.items():
            output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')


def getMainPageMLflow(mlflow_tracking_uri):

    try:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
    except ConnectionRefusedError:
        return f"Cannot connect to tracking uri {mlflow_tracking_uri}"


    current_exptid = vim.eval("s:current_exptid")
    current_runid = vim.eval("s:current_runid")
    out = [""]
    out.append("\" Press ? for help")
    out.append("")
    text, exptids = getMLflowExpts(mlflow_tracking_uri)
    out.extend(text)
    text, runids = getRunsListForExpt(mlflow_tracking_uri, current_exptid)
    out.extend(text)
    out.extend(getParamsListForRun(mlflow_tracking_uri, current_runid))
    out.extend(getMetricsListForRun(mlflow_tracking_uri, current_runid))
    out.extend(getTagsListForRun(mlflow_tracking_uri, current_runid))
    return out


    # Extra snippets while i'm still developing...

    #client = MlflowClient()
    #exp_id = client.get_experiment_by_name("<experiment_id>").experiment_id
    #runs = mlflow.search_runs("<experiment_id>", "metrics.r2 < 0.1")
    #runs = mlflow.search_runs(None, "metrics.r2 < 0.1")
    #print(exp_id)
    #runs = mlflow.search_runs()
    #print(runs)
