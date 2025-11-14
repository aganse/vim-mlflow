from datetime import datetime
from urllib.request import urlopen, Request
import math
import os
import json

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
        visible_rows = []
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
            status = run.info.status or "-"
            user = runtags.get("mlflow.user") or run.info.user_id or "-"
            stage_letter = ""
            if view_type == ViewType.ALL:
                stage_letter = lifecycles.get(run.info.lifecycle_stage, run.info.lifecycle_stage[:1].upper())
            visible_rows.append(
                {
                    "mark": mark,
                    "run_id": run.info.run_id[:5],
                    "stage": stage_letter,
                    "start": st,
                    "status": status,
                    "user": user,
                    "name": runname,
                }
            )

        if visible_rows:
            status_width = max(len(row["status"]) for row in visible_rows)
            user_width = max(len(row["user"]) for row in visible_rows)
        else:
            status_width = user_width = 1

        for row in visible_rows:
            stage_prefix = f"{row['stage']} " if row["stage"] else ""
            status_col = row["status"].ljust(status_width)
            user_col = row["user"].ljust(user_width)
            output_lines.append(
                f"{row['mark']}#{row['run_id']}: {stage_prefix}{row['start']}  {status_col}  {user_col}  {row['name']}"
            )
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

        metric_histories = {}
        output_lines = []
        output_lines.append(f"Metrics in run #{current_runid[:5]}:")
        output_lines.append(vim.eval("g:vim_mlflow_icon_vdivider")*30)
        for k,v in run.data.metrics.items():
            history = client.get_metric_history(current_runid, k)
            metric_histories[k] = [
                {
                    "step": m.step,
                    "timestamp": m.timestamp,
                    "value": m.value,
                }
                for m in history
            ]
            suffix = ""
            if len(history) > 1:
                suffix = "  [final value; x here to plot]"
            output_lines.append(f"  {k}: {v:.4g}{suffix}")
        output_lines.append("")

        # Cache histories in a global dict so Vimscript can access them.
        vim.vars['vim_mlflow_metric_histories'] = {current_runid: metric_histories}
        vim.vars['vim_mlflow_current_runinfo'] = {
            "run_id": run.info.run_id,
            "run_name": run.info.run_name or "",
            "experiment_id": run.info.experiment_id,
        }
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


def _clean_metric_history(history):
    cleaned = []
    for idx, point in enumerate(history):
        value = point.get("value")
        if value is None:
            continue
        try:
            val = float(value)
        except (TypeError, ValueError):
            continue
        if isinstance(val, float) and math.isnan(val):
            continue
        entry = {
            "value": val,
            "step": point.get("step", idx),
            "timestamp": point.get("timestamp"),
        }
        if entry["step"] is None:
            entry["step"] = idx
        cleaned.append(entry)
    return cleaned


def _downsample_points(points, target_len):
    if len(points) <= target_len:
        return points
    ratio = len(points) / float(target_len)
    downsampled = []
    for i in range(target_len):
        start = int(round(i * ratio))
        end = int(round((i + 1) * ratio))
        if end <= start:
            end = start + 1
        slice_points = points[start:end]
        if not slice_points:
            slice_points = points[start:start + 1]
        avg_x = sum(p[0] for p in slice_points) / len(slice_points)
        avg_y = sum(p[1] for p in slice_points) / len(slice_points)
        downsampled.append((avg_x, avg_y))
    return downsampled


def _collect_artifacts(client, run_id, path="", depth=0, max_depth=50):
    nodes = []
    try:
        artifacts = client.list_artifacts(run_id, path)
    except Exception:
        return nodes
    for item in sorted(artifacts, key=lambda a: a.path):
        node = {
            "path": item.path,
            "name": item.path.rsplit("/", 1)[-1],
            "is_dir": item.is_dir,
            "children": [],
        }
        if item.is_dir and depth < max_depth:
            node["children"] = _collect_artifacts(client, run_id, item.path, depth + 1, max_depth)
        nodes.append(node)
    return nodes


def _is_text_artifact(name):
    lowered = name.lower()
    if lowered == "mlmodel":
        return True
    for suffix in (".txt", ".json", ".yaml", ".yml"):
        if lowered.endswith(suffix):
            return True
    return False


def _render_artifact_section(short_run_id, tree, expanded, mark_icon, open_icon, divider_char, max_depth=3):
    indent_unit = "  "
    lines = [f"Artifacts in run #{short_run_id}:", divider_char * 30]
    info_entries = []

    def walk(nodes, depth):
        for node in sorted(nodes, key=lambda n: (not n["is_dir"], n["name"])):
            indent = indent_unit * depth
            if node["is_dir"]:
                is_open = bool(expanded.get(node["path"]))
                icon = open_icon if is_open else mark_icon
                display = f"{indent}{icon} {node['name']}/"
                info_entries.append(
                    {
                        "offset": len(lines),
                        "type": "dir",
                        "path": node["path"],
                        "expanded": is_open,
                        "depth": depth,
                    }
                )
                lines.append(display)
                if is_open and depth < max_depth:
                    walk(node["children"], depth + 1)
            else:
                openable = _is_text_artifact(node["name"])
                display = f"{indent}{indent_unit}{node['name']}"
                info_entries.append(
                    {
                        "offset": len(lines),
                        "type": "file",
                        "path": node["path"],
                        "openable": openable,
                        "depth": depth,
                    }
                )
                lines.append(display)

    walk(tree, 0)
    lines.append("")
    return lines, info_entries


def download_artifact_file(tracking_uri, run_id, artifact_path, target_dir):
    mlflow.set_tracking_uri(tracking_uri)
    client = MlflowClient()
    os.makedirs(target_dir, exist_ok=True)
    local_path = client.download_artifacts(run_id, artifact_path, dst_path=target_dir)
    if os.path.isdir(local_path):
        raise IsADirectoryError(f"{artifact_path} is a directory")
    return local_path


def render_metric_plot(run_id, metric_name, history, width, height, xaxis_mode, experiment_id, run_name):
    experiment_id = str(experiment_id) if experiment_id else "-"
    run_name = str(run_name) if run_name else ""
    cleaned = _clean_metric_history(history)
    width = max(10, int(width))
    run_prefix = f"Metric {metric_name} for expt #{experiment_id} run #{run_id[:5]}"
    max_title_len = 11 + width
    available = max_title_len - len(run_prefix) - 1
    if run_name and available > 0:
        title = f"{run_prefix} {run_name[:available]}"
    else:
        title = run_prefix
    if len(cleaned) <= 1:
        return (["Metric has insufficient data points to plot."], title)

    xaxis_mode = (xaxis_mode or "step").lower()
    if xaxis_mode not in {"step", "timestamp"}:
        xaxis_mode = "step"

    if xaxis_mode == "timestamp" and all(pt.get("timestamp") is not None for pt in cleaned):
        baseline = cleaned[0]["timestamp"]
        xs = [(pt["timestamp"] - baseline) / 1000.0 for pt in cleaned]
        x_label = "seconds (relative)"
    else:
        xs = [pt.get("step") for pt in cleaned]
        x_label = "step"
    xs = [idx if x is None else x for idx, x in enumerate(xs)]

    points = list(zip(xs, (pt["value"] for pt in cleaned)))
    height = max(5, int(height))
    points = _downsample_points(points, width)

    x_min = min(p[0] for p in points)
    x_max = max(p[0] for p in points)
    if x_max == x_min:
        x_max = x_min + 1.0

    values = [pt["value"] for pt in cleaned]
    y_min = min(values)
    y_max = max(values)
    if y_max == y_min:
        y_max = y_min + 1e-9
    final_value = cleaned[-1]["value"]

    point_icon = vim.eval("g:vim_mlflow_icon_plotpts") or "*"
    filler_icon = vim.eval("g:vim_mlflow_icon_between_plotpts") or "."
    grid = [[" " for _ in range(width)] for _ in range(height)]
    coords = []
    for x, y in points:
        col = int(round((x - x_min) / (x_max - x_min) * (width - 1)))
        row = height - 1 - int(round((y - y_min) / (y_max - y_min) * (height - 1)))
        col = max(0, min(width - 1, col))
        row = max(0, min(height - 1, row))
        grid[row][col] = point_icon
        coords.append((col, row))

    for (c1, r1), (c2, r2) in zip(coords, coords[1:]):
        dc = c2 - c1
        dr = r2 - r1
        steps = max(abs(dc), abs(dr))
        if steps == 0:
            continue
        for step in range(1, steps):
            col = int(round(c1 + step * dc / steps))
            row = int(round(r1 + step * dr / steps))
            if 0 <= col < width and 0 <= row < height and grid[row][col] == " ":
                grid[row][col] = filler_icon

    top_label = f"{y_max:.4g}".rjust(10)
    bottom_label = f"{y_min:.4g}".rjust(10)
    vdivider = vim.eval("g:vim_mlflow_icon_vdivider") or "-"
    hdivider = vim.eval("g:vim_mlflow_icon_hdivider") or "|"
    plot_body = []
    for idx, row_data in enumerate(grid):
        if idx == 0:
            label = top_label + " "
        elif idx == height - 1:
            label = bottom_label + " "
        else:
            label = " " * 11
        plot_body.append(label + hdivider + "".join(row_data))

    axis_line = " " * 11 + "+" + vdivider * width
    x_min_str = f"{x_min:.4g}"
    x_max_str = f"{x_max:.4g}"
    middle_space = width - len(x_min_str) - len(x_max_str)
    if middle_space < 1:
        middle_space = 1
    x_bounds_line = " " * 11 + x_min_str + " " * middle_space + x_max_str

    lines = []
    lines.append("")
    lines.extend(plot_body)
    lines.append(axis_line)
    lines.append(x_bounds_line)
    lines.append("")
    lines.append(f"x-axis ({x_label}) range: {x_min:.4g} -> {x_max:.4g}")
    lines.append(f"value range: {y_min:.4g} -> {y_max:.4g}  final: {final_value:.4g}")
    lines.append(f"points logged: {len(cleaned)}  plotted: {len(points)}")

    return lines, title


def getMainPageMLflow(mlflow_tracking_uri):

    out = []
    version = vim.eval("get(g:, 'vim_mlflow_version', 'dev')")
    out.append(f"Vim-MLflow v{version}")
    out.append("\" Press ? for help")
    out.append("")
    out.append("")
    vim.vars['vim_mlflow_artifact_lineinfo'] = {}
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
            if vim.eval("s:artifacts_are_showing") == "1":
              expanded_json = vim.eval("json_encode(get(g:, 'vim_mlflow_artifact_expanded', {}))")
              expanded = json.loads(expanded_json)
              mark_icon = vim.eval("g:vim_mlflow_icon_markrun") or ">"
              open_icon = vim.eval("g:vim_mlflow_icon_scrolldown") or "v"
              divider_char = vim.eval("g:vim_mlflow_icon_vdivider") or "-"
              max_depth = int(vim.eval("g:vim_mlflow_artifacts_max_depth"))
              client = MlflowClient(tracking_uri=mlflow_tracking_uri)
              tree = _collect_artifacts(client, vim.eval("s:current_runid"), max_depth=max_depth)
              artifact_lines, artifact_info = _render_artifact_section(
                  vim.eval("s:current_runid")[:5],
                  tree,
                  expanded,
                  mark_icon,
                  open_icon,
                  divider_char,
                  max_depth=max_depth,
              )
              start_line = len(out) + 1
              lineinfo_map = {}
              for entry in artifact_info:
                  offset = entry.pop("offset")
                  target_line = start_line + offset
                  entry["line"] = target_line
                  lineinfo_map[str(target_line)] = entry
              vim.vars['vim_mlflow_artifact_lineinfo'] = lineinfo_map
              out.extend(artifact_lines)
            else:
              vim.vars['vim_mlflow_artifact_lineinfo'] = {}
        else:
            vim.vars['vim_mlflow_artifact_lineinfo'] = {}
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
