import contextlib
import io
import json
import math
import os
from urllib.parse import urlencode
from urllib.request import urlopen

import mlflow
import vim
from mlflow.entities import ViewType
from mlflow.tracking import MlflowClient

from vim_mlflow_cache import get_session

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


def _get_cache_mode():
    """Return the configured run-summary cache mode."""
    cache_mode = vim.eval("get(g:, 'vim_mlflow_runs_cache_mode', 'selected_expt')")
    if cache_mode not in {"selected_expt", "all_expts"}:
        return "selected_expt"
    return cache_mode


def _get_session(mlflow_tracking_uri):
    """Return the active cache session for the current Vim settings."""
    view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
    view_type = VIEWTYPE_MAP.get(view_idx, ViewType.ACTIVE_ONLY)
    timeout = float(vim.eval("g:vim_mlflow_timeout"))
    return get_session(mlflow_tracking_uri, view_type, _get_cache_mode(), timeout)


def _vim_flag(expression):
    """Interpret a Vimscript boolean-like value as a Python bool."""
    return str(vim.eval(expression)) == "1"


def getMLflowExpts(session, force_refresh=False):
    """Render the experiment list from cached MLflow data."""
    try:
        lifecycles = {"active": "A", "deleted": "D"}
        view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
        expts_df = session.get_experiments_df(force_refresh=force_refresh)

        output_lines = []
        num_expts_viewtype = len(expts_df.index)
        vim.command("let s:num_expts='" + str(num_expts_viewtype) + "'")
        output_lines.append(
            f"{vim.eval('s:num_expts')} {VIEWTYPE_LABELS.get(view_idx, VIEWTYPE_LABELS[1])} "
            "Experiments:"
        )
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:expts_first_idx")) == 0:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollup")
        else:
            scrollicon = ""
        output_lines.append(scrollicon + vim.eval("g:vim_mlflow_icon_vdivider") * 30)
        beginexpt_idx = int(vim.eval("s:expts_first_idx"))
        endexpt_idx = int(vim.eval("s:expts_first_idx")) + int(
            vim.eval("g:vim_mlflow_expts_length")
        )
        visible_expts = expts_df.iloc[beginexpt_idx:endexpt_idx]
        view_type = session.view_type
        for _, expt in visible_expts.iterrows():
            if view_type == ViewType.ALL:
                stage_letter = lifecycles.get(
                    expt["lifecycle_stage"], expt["lifecycle_stage"][:1].upper()
                )
                output_lines.append(f"#{expt['experiment_id']}: {stage_letter} {expt['name']}")
            else:
                output_lines.append(f"#{expt['experiment_id']}: {expt['name']}")
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:expts_first_idx")) == int(
                vim.eval("s:num_expts-min([g:vim_mlflow_expts_length, s:num_expts])")
            ):
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrolldown")
        else:
            scrollicon = ""
        output_lines.append(scrollicon)
        return output_lines, expts_df["experiment_id"].tolist()

    except ModuleNotFoundError:
        print(
            "Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup."
        )


def getRunsListForExpt(session, current_exptid, force_refresh=False):
    """Render the run list for one experiment from cached summaries."""
    try:
        lifecycles = {"active": "A", "deleted": "D"}
        view_idx = int(vim.eval("g:vim_mlflow_viewtype"))
        runs_df = session.get_runs_df(str(current_exptid), force_refresh=force_refresh)

        output_lines = []
        num_runs_viewtype = len(runs_df.index)
        vim.command("let s:num_runs='" + str(num_runs_viewtype) + "'")
        output_lines.append(
            f"{vim.eval('s:num_runs')} {VIEWTYPE_LABELS.get(view_idx, VIEWTYPE_LABELS[1])} "
            f"Runs in expt #{current_exptid}:"
        )
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:runs_first_idx")) == 0:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollup")
        else:
            scrollicon = ""
        output_lines.append(scrollicon + vim.eval("g:vim_mlflow_icon_vdivider") * 30)
        beginrun_idx = int(vim.eval("s:runs_first_idx"))
        endrun_idx = int(vim.eval("s:runs_first_idx")) + int(
            vim.eval("g:vim_mlflow_runs_length")
        )
        visible_rows = []
        visible_runs = runs_df.iloc[beginrun_idx:endrun_idx]
        view_type = session.view_type
        for _, run in visible_runs.iterrows():
            mark = " "
            if run["run_id_short"] in vim.eval("s:markruns_list"):
                mark = vim.eval("g:vim_mlflow_icon_markrun")
            stage_letter = ""
            if view_type == ViewType.ALL:
                stage_letter = lifecycles.get(
                    run["lifecycle_stage"], run["lifecycle_stage"][:1].upper()
                )
            visible_rows.append(
                {
                    "mark": mark,
                    "run_id": run["run_id_short"],
                    "stage": stage_letter,
                    "start": run["start_time"],
                    "status": run["status"],
                    "duration": run["duration"],
                    "user": run["user"],
                    "name": run["run_name"],
                }
            )

        if visible_rows:
            status_width = max(len(row["status"]) for row in visible_rows)
            duration_width = max(len(row["duration"]) for row in visible_rows)
            user_width = max(len(row["user"]) for row in visible_rows)
        else:
            status_width = duration_width = user_width = 1

        for row in visible_rows:
            stage_prefix = f"{row['stage']} " if row["stage"] else ""
            status_col = row["status"].ljust(status_width)
            duration_col = row["duration"].rjust(duration_width)
            user_col = row["user"].ljust(user_width)
            output_lines.append(
                f"{row['mark']}#{row['run_id']}: {stage_prefix}{row['start']}  {status_col}  "
                f"{duration_col}  {user_col}  {row['name']}"
            )
        if vim.eval("g:vim_mlflow_show_scrollicons"):
            if int(vim.eval("s:runs_first_idx")) == int(
                vim.eval("s:num_runs-min([g:vim_mlflow_runs_length, s:num_runs])")
            ):
                scrollicon = vim.eval("g:vim_mlflow_icon_scrollstop")
            else:
                scrollicon = vim.eval("g:vim_mlflow_icon_scrolldown")
        else:
            scrollicon = ""
        output_lines.append(scrollicon)
        return output_lines, runs_df["run_id"].tolist()

    except ModuleNotFoundError:
        print(
            "Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup."
        )


def getMetricsListForRun(session, current_runid, show=True, header_icon="", force_refresh=False):
    """Render the metrics section for one run and cache metric histories."""
    try:
        run = session.get_run_detail(current_runid, force_refresh=force_refresh)
        metrics = run["data"]["metrics"]

        metric_histories = {}
        output_lines = []
        metric_offsets = []
        prefix = f"{header_icon} " if header_icon else ""
        divider = vim.eval("g:vim_mlflow_icon_vdivider") * 30
        output_lines.append(f"{prefix}Metrics in run #{current_runid[:5]}:")
        output_lines.append(divider)
        if show:
            for k, v in metrics.items():
                history = session.get_metric_history(
                    current_runid, k, force_refresh=force_refresh
                )
                metric_histories[k] = history
                suffix = ""
                if len(history) > 1:
                    suffix = "  [final value; o to plot]"
                metric_offsets.append(len(output_lines))
                output_lines.append(f"  {k}: {v:.4g}{suffix}")
        else:
            metric_histories = {}
        output_lines.append("")

        # Cache histories in a global dict so Vimscript can access them.
        vim.vars["vim_mlflow_metric_histories"] = {current_runid: metric_histories}
        vim.vars["vim_mlflow_current_runinfo"] = {
            "run_id": run["info"]["run_id"],
            "run_name": run["info"]["run_name"] or "",
            "experiment_id": run["info"]["experiment_id"],
        }
        return output_lines, metric_offsets

    except ModuleNotFoundError:
        print(
            "Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup."
        )


def getParamsListForRun(session, current_runid, show=True, header_icon="", force_refresh=False):
    """Render the params section for one run."""
    try:
        run = session.get_run_detail(current_runid, force_refresh=force_refresh)

        output_lines = []
        prefix = f"{header_icon} " if header_icon else ""
        divider = vim.eval("g:vim_mlflow_icon_vdivider") * 30
        output_lines.append(f"{prefix}Params in run #{current_runid[:5]}:")
        output_lines.append(divider)
        if show:
            for k, v in run["data"]["params"].items():
                output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print(
            "Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup."
        )


def getTagsListForRun(session, current_runid, show=True, header_icon="", force_refresh=False):
    """Render the tags section for one run."""
    try:
        run = session.get_run_detail(current_runid, force_refresh=force_refresh)

        output_lines = []
        prefix = f"{header_icon} " if header_icon else ""
        divider = vim.eval("g:vim_mlflow_icon_vdivider") * 30
        output_lines.append(f"{prefix}Tags in run #{current_runid[:5]}:")
        output_lines.append(divider)
        if show:
            for k, v in run["data"]["tags"].items():
                output_lines.append(f"  {k}: {v}")
        output_lines.append("")
        return output_lines

    except ModuleNotFoundError:
        print(
            "Sorry, `mlflow` is not installed. See :h vim-mlflow for more details on setup."
        )


def _clean_metric_history(history):
    """Normalize metric history points into plottable numeric entries."""
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
    """Reduce plotted points to fit the target display width."""
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
            slice_points = points[start: start + 1]
        avg_x = sum(p[0] for p in slice_points) / len(slice_points)
        avg_y = sum(p[1] for p in slice_points) / len(slice_points)
        downsampled.append((avg_x, avg_y))
    return downsampled


def _collect_artifacts(client, run_id, path="", depth=0, max_depth=50):
    """Collect an artifact tree for one run up to the requested depth."""
    nodes = []
    try:
        actual_path = path or None
        if actual_path is None:
            artifacts = client.list_artifacts(run_id)
        else:
            artifacts = client.list_artifacts(run_id, actual_path)
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
            node["children"] = _collect_artifacts(
                client, run_id, item.path, depth + 1, max_depth
            )
        nodes.append(node)
    return nodes


def _is_text_artifact(name):
    """Return whether an artifact should be opened as inline text."""
    lowered = name.lower()
    if lowered == "mlmodel":
        return True
    for suffix in (".txt", ".json", ".yaml", ".yml"):
        if lowered.endswith(suffix):
            return True
    return False


def _render_artifact_section(
    short_run_id,
    tree,
    expanded,
    mark_icon,
    open_icon,
    divider_char,
    show_children=True,
    max_depth=3,
    header_icon=None,
):
    """Render artifact tree lines plus metadata for clickable rows."""
    indent_unit = "  "
    prefix = f"{header_icon} " if header_icon else ""
    lines = [f"{prefix}Artifacts in run #{short_run_id}:", divider_char * 30]
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

    if show_children:
        walk(tree, 0)
    lines.append("")
    return lines, info_entries


def download_artifact_file(tracking_uri, run_id, artifact_path, target_dir):
    """Download one artifact file for local viewing."""
    if not tracking_uri.startswith(("http://", "https://")):
        raise ValueError(f"tracking_uri must be http:// or https://, got: {tracking_uri!r}")
    os.makedirs(target_dir, exist_ok=True)
    params = urlencode({"run_uuid": run_id, "path": artifact_path})
    url = f"{tracking_uri.rstrip('/')}/get-artifact?{params}"
    local_path = os.path.join(target_dir, run_id, *artifact_path.split("/"))
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    with urlopen(url) as response:
        content = response.read()
    with open(local_path, "wb") as f:
        f.write(content)
    if os.path.isdir(local_path):
        raise IsADirectoryError(f"{artifact_path} is a directory")
    return local_path


def read_artifact_display_lines(artifact_path, local_path):
    """Return artifact lines for display, pretty-printing JSON when possible."""
    if artifact_path.lower().endswith(".json"):
        try:
            with open(local_path, encoding="utf-8") as infile:
                payload = json.load(infile)
            rendered = json.dumps(payload, indent=2, ensure_ascii=False)
            return rendered.splitlines() or [""]
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            pass

    with open(local_path, encoding="utf-8", errors="replace") as infile:
        content = infile.read().splitlines()
    return content or [""]


def render_metric_plot(
    run_id, metric_name, history, width, height, xaxis_mode, experiment_id, run_name
):
    """Render an ASCII plot for one metric history."""
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

    if xaxis_mode == "timestamp" and all(
        pt.get("timestamp") is not None for pt in cleaned
    ):
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


def getMainPageMLflow(mlflow_tracking_uri, force_refresh=False):
    """Render the main MLflow sidebar from cached and lazy-loaded data."""

    out = []
    version = vim.eval("get(g:, 'vim_mlflow_version', 'dev')")
    out.append(f"Vim-MLflow v{version}")
    out.append('" Press ? for help')
    out.append("")
    out.append("")
    vim.vars["vim_mlflow_artifact_lineinfo"] = {}
    vim.vars["vim_mlflow_metric_lines"] = []
    vim.vars["vim_mlflow_section_headers"] = []
    session = _get_session(mlflow_tracking_uri)
    if session.ensure_available(force_refresh=force_refresh):
        text, exptids = getMLflowExpts(session, force_refresh=force_refresh)
        out.extend(text)
        out.append("")
        current_exptid = vim.eval("s:current_exptid")
        if exptids and current_exptid not in exptids:
            current_exptid = exptids[0]
            vim.command("let s:current_exptid='" + current_exptid + "'")
        elif current_exptid == "" and exptids:
            current_exptid = exptids[0]
            vim.command("let s:current_exptid='" + current_exptid + "'")

        if current_exptid:
            session.prime_runs_cache(current_exptid, force_refresh=force_refresh)
            text, runids = getRunsListForExpt(session, current_exptid)
            out.extend(text)
            out.append("")
        else:
            runids = []

        if runids:
            current_run = vim.eval("s:current_runid")
            if current_run == "":
                current_run = runids[0]
            elif len(current_run) == 5:
                current_run = session.find_run_id(current_exptid, current_run)
            elif current_run not in runids:
                current_run = runids[0]
            vim.command("let s:current_runid='" + current_run + "'")
            if force_refresh:
                session.get_run_detail(current_run, force_refresh=True)

            section_order = vim.eval("g:vim_mlflow_section_order")
            if not section_order:
                section_order = ["params", "metrics", "tags", "artifacts"]
            states = {
                "params": _vim_flag("s:params_are_showing"),
                "metrics": _vim_flag("s:metrics_are_showing"),
                "tags": _vim_flag("s:tags_are_showing"),
                "artifacts": _vim_flag("s:artifacts_are_showing"),
            }
            open_icon = vim.eval("g:vim_mlflow_icon_scrolldown") or "v"
            closed_icon = vim.eval("g:vim_mlflow_icon_markrun") or ">"
            short_run = current_run[:5]
            section_header_entries = []
            metric_line_numbers = []
            for section in section_order:
                if section not in ("params", "metrics", "tags", "artifacts"):
                    continue
                show = states.get(section, False)
                header_icon = open_icon if show else closed_icon
                header_line = len(out) + 1
                if section == "params":
                    out.extend(
                        getParamsListForRun(
                            session,
                            current_run,
                            show=show,
                            header_icon=header_icon,
                        )
                    )
                elif section == "metrics":
                    metrics_output, offsets = getMetricsListForRun(
                        session,
                        current_run,
                        show=show,
                        header_icon=header_icon,
                    )
                    out.extend(metrics_output)
                    if show:
                        metric_line_numbers.extend(
                            [header_line + offset for offset in offsets]
                        )
                elif section == "tags":
                    out.extend(
                        getTagsListForRun(
                            session,
                            current_run,
                            show=show,
                            header_icon=header_icon,
                        )
                    )
                elif section == "artifacts":
                    divider_char = vim.eval("g:vim_mlflow_icon_vdivider") or "-"
                    max_depth = int(vim.eval("g:vim_mlflow_artifacts_max_depth"))
                    mark_icon = closed_icon
                    open_dir_icon = open_icon
                    if show:
                        expanded_json = vim.eval(
                            "json_encode(get(g:, 'vim_mlflow_artifact_expanded', {}))"
                        )
                        expanded = json.loads(expanded_json)
                        tree = session.get_artifact_tree(
                            current_run,
                            max_depth,
                            _collect_artifacts,
                        )
                        artifact_lines, artifact_info = _render_artifact_section(
                            short_run,
                            tree,
                            expanded,
                            mark_icon,
                            open_dir_icon,
                            divider_char,
                            show_children=show,
                            max_depth=max_depth,
                            header_icon=header_icon,
                        )
                        start_line = len(out) + 1
                        lineinfo_map = {}
                        for entry in artifact_info:
                            offset = entry.pop("offset")
                            target_line = start_line + offset
                            entry["line"] = target_line
                            lineinfo_map[str(target_line)] = entry
                        vim.vars["vim_mlflow_artifact_lineinfo"] = lineinfo_map
                        out.extend(artifact_lines)
                    else:
                        vim.vars["vim_mlflow_artifact_lineinfo"] = {}
                        header = f"{header_icon} Artifacts in run #{short_run}:"
                        out.extend([header, divider_char * 30, ""])
                section_header_entries.append({"line": header_line, "section": section})
            vim.vars["vim_mlflow_section_headers"] = section_header_entries
            vim.vars["vim_mlflow_metric_lines"] = metric_line_numbers
        else:
            vim.command("let s:current_runid=''")
            vim.vars["vim_mlflow_artifact_lineinfo"] = {}
            vim.vars["vim_mlflow_section_headers"] = []
            vim.vars["vim_mlflow_metric_lines"] = []
    else:
        out.append("Could not connect to mlflow_tracking_uri")
        out.append(mlflow_tracking_uri)
        out.append(
            f"within the g:vim_mlflow_timeout={float(vim.eval('g:vim_mlflow_timeout')):.2f}"
        )
        out.append("Are you sure that's the right URI?")
        vim.vars["vim_mlflow_section_headers"] = []
        vim.vars["vim_mlflow_metric_lines"] = []
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
        return urlopen(url, timeout=timeout).getcode() == 200
    except Exception:
        return False
