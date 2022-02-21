try:
    from datetime import datetime
    import mlflow
    my_tracking_uri = "http://localhost:5000"
    mlflow.set_tracking_uri(my_tracking_uri)
    print('MLFLOW tracking URI is', mlflow.get_tracking_uri())

    from mlflow.entities import ViewType
    from mlflow.tracking import MlflowClient

    client = MlflowClient()
    #exp_id = client.get_experiment_by_name("<experiment_id>").experiment_id
    #runs = mlflow.search_runs("<experiment_id>", "metrics.r2 < 0.1")
    #runs = mlflow.search_runs(None, "metrics.r2 < 0.1")
    #print(exp_id)
    #runs = mlflow.search_runs()
    #print(runs)

    expts = mlflow.list_experiments()
    print("Experiments:")
    print("------------")
    for expt in expts:
        print(expt.experiment_id, expt.name)
    print(" ")

    current_exptid = "0"
    #expt = mlflow.get_experiment(current_exptid)
    #print(expt)
    #print(" ")

    runs = mlflow.list_run_infos(current_exptid, run_view_type=ViewType.ACTIVE_ONLY)  # ACTIVE_ONLY, DELETED_ONLY, or ALL
    print("Runs in current expt:")
    print("---------------------")
    for run in runs:
        st = datetime.utcfromtimestamp(run.start_time/1e3).strftime('%Y-%m-%d %H:%M:%S')
        print(f"{run.run_id[:5]}: {st}")
    print(" ")

    current_runid = run.run_id
    run = mlflow.get_run(current_runid)
    #print(run)

    print("Metrics:")
    for k,v in run.data.metrics.items():
        print(f"  {k}: {v}")
    print("Parameters:")
    for k,v in run.data.params.items():
        print(f"  {k}: {v}")
    #print("Tags:")
    #for k,v in run.data.tags.items():
    #    print(f"  {k}: {v}")

except ModuleNotFoundError:
    print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')
