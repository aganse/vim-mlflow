try:
    import mlflow
    print('MLFLOW tracking URI is', mlflow.get_tracking_uri())


    #from mlflow.tracking import MlflowClient

    #client = MlflowClient()
    #exp_id = client.get_experiment_by_name("<experiment_id>").experiment_id
    #runs = mlflow.search_runs("<experiment_id>", "metrics.r2 < 0.1")
    #print(exp_id)

    #runs = mlflow.search_runs("<experiment_id>")
    #print(runs)



except ModuleNotFoundError:
    print('Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup.')
