# vim-mlflow
![version](https://img.shields.io/badge/version-1.0.0-green.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

`vim‑mlflow` is a lightweight Vim plugin that lets you browse and interact with
MLflow experiments, runs, metrics, parameters, tags, and artifacts directly
in your Vim editor.  It opens a dedicated sidebar and a detail pane so you can
explore data without leaving the terminal, even allowing you to plot metric
histories and browse non-graphical artifacts.  The plugin is written in
Vimscript with embedded Python and talks to MLflow through its Python API.
It works with both MLflow3.x and MLflow2.x ML tracking servers (but not GenAI
traces/etc currently).

> <SUP>
> :bulb: Note this repo is part of a group that you might find useful together
> (but all are separate tools that can be used independently):
>
> * [aganse/docker_mlflow_db](https://github.com/aganse/docker_mlflow_db):
>     ready-to-run MLflow server with PostgreSQL, AWS S3, Nginx
>
> * [aganse/py_tf2_gpu_dock_mlflow](https://github.com/aganse/py_tf2_gpu_dock_mlflow):
>     ready-to-run Python/Tensorflow2/MLflow-Projects setup to train models on GPU
>
> * [aganse/vim_mlflow](https://github.com/aganse/vim-mlflow):
>     a Vim plugin to browse the MLflow parameters and metrics instead of GUI
> </SUP>
<P>&nbsp;<P>

[![example vim-mlflow screenshot](doc/demo.gif)](doc/demo.gif)

## Summary
* Open a sidebar (`__MLflow__`) that lists all experiments on the connected
  MLflow server.
* Expand experiments to see individual runs.
* Drill into a run to view metrics, parameters, tags, and artifacts.
* Open a run comparison pane (`__MLflowRuns__`) to compare metrics
  across multiple selected runs.
* View ASCII plots of metric histories, and text artifacts inline.
* Completely configurable via Vim variables (e.g. in your ~/.vimrc file).

> [!NOTE]
> `vim‑mlflow` requires a Python3‑enabled Vim and the `mlflow` Python package
> installed in the same environment that Vim is launched from.



## Installation
`vim‑mlflow` works in Vim versions compiled with python3 support.

#### 1. Check that your Vim supports python3:
- `vim --version | grep +python3`
- (If no +python3 line is found, install a Vim build that was compiled with Python3.)

#### 2. Highly recommended to create/use a virtual environment:
- `python3 -m venv .venv`
- `source .venv/bin/activate  # syntax for linux/mac`
- (Technically this step is optional if you really insist, but it's recommended.)

#### 3. Install the `mlflow` Python package:
- `pip install mlflow`
- The plugin imports and uses this mlflow package to connect to your MLflow
  tracking server.  For the relatively basic functions in this plugin, the
  version of the MLflow package doesn't need to exactly match that of your
  tracking server.

#### 4. Add the plugin to your plugin manager:
- *Vundle* add `Plugin 'aganse/vim-mlflow'` to .vimrc, run `:PluginInstall`.
- *Plug* add `Plug 'aganse/vim-mlflow'` to .vimrc, run `:PlugInstall`.
- *Or just path‑based* `cp -r . ~/.vim/plugin/vim-mlflow`

#### 5. Set your MLflow tracking URI (and any other config settings you like) in your ~/.vimrc:
- `let g:mlflow_tracking_uri = "http://localhost:5000"`



## Usage
Ensure you're in your python environment with MLflow before starting Vim.
Then start the plugin using `<leader>m` or `:call RunMLflow()` (e.g. on my
system the `<leader>` key is `\` so I do `\m`).
You can also update that mapping in your ~/.vimrc file to set a new leader/key
to start vim-mlflow in your Vim session, for example
`nnoremap <leader>m :call RunMLflow()<CR>`.

Starting the plugin opens the `__MLflow__` sidebar.  Navigate the cursor around
with the standard vim movement keys.  A few of the more important plugin-specific
key bindings inside the sidebar are:

| Key | Action |
|-----|--------|
| `o`, `<enter>` | Open experiment/run/plot/artifact/section under cursor |
| `r` | Requery the MLflow display |
| `<space>` | Mark runs in the runs list |
| `R` | Open the `__MLflowRuns__` window to show and compare more details for the marked runs |

Pressing `o` or `<enter>` while your cursor is on an experiment will open that
experiment, updating the Runs list.  Pressing it on a run will open that run and
update the Metrics, Parameters, Tags, and Artifacts shown from the run.  Pressing
it on a metric with a history will open an ASCII plot of that metric's time
series.  Press `?` in the sidebar for a full help listing of the keys map.



## Configuration

Only `g:mlflow_tracking_uri` is required to be set by user (e.g. in .vimrc).
But a typical small set of vim-mlflow config variables that one might set is:
```vim
" Vim-mlflow settings
let g:mlflow_tracking_uri = "http://localhost:5000"  " running locally or via ssh-tunnel
let g:vim_mlflow_icon_useunicode = 1  " default 0 value uses ascii chars instead
let g:vim_mlflow_width = get(g:, 'vim_mlflow_width', 50)  " width of mlflow window
let g:vim_mlflow_expts_length = 10  " experiments to show at a time
let g:vim_mlflow_runs_length = 15   " runs to show at a time
```

Full list of vim-mlflow config variables that may be of interest to set in .vimrc:
|           variable               |               description               |
| -------------------------------- | --------------------------------------- |
| `g:mlflow_tracking_uri` _(required)_ | The MLFLOW_TRACKING_URI of the MLflow tracking server to connect to (default is `"http://localhost:5000"`)|
| `g:vim_mlflow_timeout`           | Timeout in float seconds if cannot access MLflow tracking server (default is 0.5)|
| `g:vim_mlflow_buffername`        | Buffername of the MLflow side pane (default is `__MLflow__`)|
| `g:vim_mlflow_runs_buffername`   | Buffername of the MLflowRuns side pane (default is `__MLflow__`)|
| `g:vim_mlflow_vside`             | Which side to open the MLflow pane on: 'left' or 'right' (default is `right`)|
| `g:vim_mlflow_hside`             | Whether to open the MLflowRuns pane 'below' or 'above' (default is `below`)|
| `g:vim_mlflow_width`             | Width of the vim-mlflow window in chars (default is 70)|
| `g:vim_mlflow_height`            | Width of the vim-mlflow window in chars (default is 10)|
| `g:vim_mlflow_expts_length`      | Number of expts to show in list (default is 8)|
| `g:vim_mlflow_runs_length`       | Number of runs to show in list (default is 8)|
| `g:vim_mlflow_viewtype`          | Show 1:activeonly, 2:deletedonly, or 3:all expts and runs (default is 1)|
| `g:vim_mlflow_show_scrollicons`  | Show the little up/down scroll arrows on expt/run lists, 1 or 0 (default is 1, ie yes show them)|
| `g:vim_mlflow_icon_useunicode`   | Allow unicode vs just ascii chars in UI, 1 or 0 (default is 0, ascii)|
| `g:vim_mlflow_icon_vdivider`     | Default is `'─'` if `vim_mlflow_icon_useunicode` else `'-'`|
| `g:vim_mlflow_icon_scrollstop`   | Default is `'▰'` if `vim_mlflow_icon_useunicode` else `''`|
| `g:vim_mlflow_icon_scrollup`     | Default is `'▲'` if `vim_mlflow_icon_useunicode` else `'^'`|
| `g:vim_mlflow_icon_scrolldown`   | Default is `'▼'` if `vim_mlflow_icon_useunicode` else `'v'`|
| `g:vim_mlflow_icon_markrun`      | Default is `'▶'` if `vim_mlflow_icon_useunicode` else `'>'`|
| `g:vim_mlflow_icon_hdivider`     | Default is `'│'` if `vim_mlflow_icon_useunicode` else `'|'`|
| `g:vim_mlflow_icon_plotpts`      | Default is `'●'` if `vim_mlflow_icon_useunicode` else `'*'`|
| `g:vim_mlflow_icon_between_plotpts` | Default is `'•'` if `vim_mlflow_icon_useunicode` else `'.'`|
| `g:vim_mlflow_color_titles`      | Element highlight color label (default is `'Statement'`)|
| `g:vim_mlflow_color_divlines`    | Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_scrollicons `| Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_selectedexpt`| Element highlight color label (default is `'String'`)|
| `g:vim_mlflow_color_selectedrun` | Element highlight color label (default is `'Number'`)|
| `g:vim_mlflow_color_help`        | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_color_markrun`     | Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_hiddencol`   | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_color_plot_title`  | Highlight group for plot titles (default `'Statement'`)|
| `g:vim_mlflow_color_plot_axes`   | Highlight group for plot axes text (default `'vimParenSep'`)|
| `g:vim_mlflow_color_plotpts`     | Highlight group for plot point glyphs (default `'Constant'`)|
| `g:vim_mlflow_color_between_plotpts` | Highlight group for line segments between points (default `'Comment'`)|
| `g:vim_mlflow_plot_height`       | ASCII plot height in rows when graphing metric history (default `25`)|
| `g:vim_mlflow_plot_width`        | ASCII plot width in columns (default `70`)|
| `g:vim_mlflow_plot_xaxis`        | `'step'` or `'timestamp'` for metric plot x-axis (default `'step'`)|
| `g:vim_mlflow_plot_reuse_buffer` | If `1`, reuse a single `__MLflowMetricPlot__` buffer; if `0`, create sequential plot buffers (default `1`)|
| `g:vim_mlflow_artifacts_max_depth` | Maximum artifact directory depth shown when expanding folders (default `3`)|



## Troubleshooting

- If the plugin fails to load, double-check that `mlflow` is importable from
  the Python environment embedded in Vim (`:py3 import mlflow` should succeed).
- The sidebar can be slow on high-latency connections to MLflow, because as
  currently implemented, each refresh spins up a short-lived Python process and
  re-queries MLflow anew.  Running Vim close to the tracking server seems to
  work fine (e.g. on same machine, and fine even if the database MLflow is
  using is in AWS RDS while MLflow is in a tiny EC2 instance).  For slower
  connections, increasing `g:vim_mlflow_timeout` might help avoid access
  timeouts.  If there's demand, a future plugin version could keep a persistent
  python process that keeps state in memory and requeries the database much
  less often, but this hasn't seemed to be of much concern so far.
- Unicode icons require a font that includes box-drawing characters.  Set
  `g:vim_mlflow_icon_useunicode = 0` if glyphs look broken as the simple quick
  fix, and also note there are config vars to change individual icon characters.
- Can I view non‑text artifacts? – Text files (`*.txt`, `*.json`, `*.yaml`,
  `MLmodel`) open directly in the plugin.  Binary artifacts' filenames are
  shown but cannot be opened in terminal.



## Legacy/older versions

   Legacy/older versions of this plugin can be accessed by git checking out an
   earlier version locally, and then referencing it in your .vimrc like
   (e.g. for Vundle) `Plugin 'file:///my/path/to/python/vim-mlflow'`.

   |  vim-mlflow git tag  | tested with mlflow version |
   | ---------------------| -------------------------- |
   | v0.8                 |  1.26.1                    |
   | v0.9                 |  1.30.0, 2.7.1             |
   | v1.0.0 (this version)|  2.12.0, 2.19.0, 3.6.0     |



## Making the animated screen-shot gif

* `pip install [asciinema](https://github.com/asciinema/asciinema)`
* `asciinema rec demo.cast  # start recording terminal screen to file`
* [manually conduct the usage example sequence, which gets saved to file]
* install [agg](https://github.com/asciinema/agg) from e.g.
  [premade binary for mac](https://github.com/asciinema/agg/releases/download/v1.3.0/agg-aarch64-apple-darwin)
* `agg --speed 2 demo.cast demo.gif`  # convert the asciinema cast to animated gif



## Acknowledgements

With many thanks to:
* The Writing Vim plugin in Python article by Timur Rubeko, 2017 Aug 11, at
  http://candidtim.github.io/vim/2017/08/11/write-vim-plugin-in-python.html
* Analyzing Your MLflow Data with DataFrames by Max Allen, 2019 Oct 3, at
  https://slacker.ro/2019/10/03/analyzing-your-mlflow-data-with-dataframes
* The Python Interface to Vim, 2019 Dec 07, at
  https://vimhelp.org/if_pyth.txt.html#python-vim
* Alternative to execfile in Python 3, Stack Overflow, 2011 Jun 15 at
  https://stackoverflow.com/questions/6357361/alternative-to-execfile-in-python-3/6357418#6357418
* MLFlow Python API at
  https://www.mlflow.org/docs/latest/python_api/mlflow.html
* MLFlow REST API at
  https://www.mlflow.org/docs/latest/rest-api.html
* MLFlow Projects page at
  https://www.mlflow.org/docs/latest/projects.html
