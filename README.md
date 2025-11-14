# vim-mlflow
A Vim plugin to browse the MLflow parameters and metrics from within Vim in a
terminal instead of (or in additional to) the MLflow webapp GUI.

> <SUP>
> :bulb: Note this repo is part of a trio that you might find useful together
> (but all are separate tools that can be used independently):
>   
> * [aganse/docker_mlflow_db](https://github.com/aganse/docker_mlflow_db):
>     ready-to-run MLflow server with PostgreSQL, AWS S3, Nginx
>   
> * [aganse/py_tf2_gpu_dock_mlflow](https://github.com/aganse/py_tf2_gpu_dock_mlflow):
>     ready-to-run Python/Tensorflow2/MLflow setup to train models on GPU
>   
> * [aganse/vim_mlflow](https://github.com/aganse/vim-mlflow):
>     a Vim plugin to browse the MLflow parameters and metrics instead of GUI
> </SUP>
<P>&nbsp;<P>


## Summary

Vim-mlflow is a Vim plugin to view and browse in Vim the results one sees in an
MLFlow website.  In a sidebar it provides scrollable lists of experiments and
runs, from which one can drill into run attributes.  One can also mark runs
across multiple experiments to list together in a more detailed runs buffer that
allows hiding and arranging its columns.

[![example vim-mlflow screenshot](doc/demo.gif)](doc/demo.gif)


## A few quick caveats to note

As my first Vim plugin, it is a beginning (but fully functional) work in
progress, so there are some important caveats to note in advance:

* It does require the MLFlow python package to be installed in the environment
  that Vim is run in, and a version of Vim that supports python3.  (Detailed
  instructions for this below.)

* My current level of understanding of vim plugin scripting didn't see a way
  to persist the python process over the full Vim session rather than an
  individual function call (see e.g. `MainPageMLflow()` in vim-mlflow.vim
  if interested).  The consequence of this is that vim-mlflow restarts the
  python process on each refresh and navigation step, which in turn means it
  requeries the MLFlow server at each step as well.  In my experimentation,
  if the user is running Vim on the same machine as the MLFlow server, or the
  network connection between the two is fast (say on same LAN), there's no
  or little problem here, even with the fairly-extensive MLFlow database I run
  in my workplace.  However, when the systems running Vim and the MLFlow server
  are separated by a slower or less consistent network connection (e.g. running
  Vim on a machine at home connecting to MLFlow server at work), then things
  can be excrutiatingly slow.  But in my own case, from home we log in to
  servers at work and always do everything there, so this wasn't a significant
  problem.  Still, even in addition to this aspect, it could do to be much more
  snappy; so multiple reasons to resolve this.  I would love to hear recommended
  ways to refactor the plugin with a persistent python process that could hold
  some dataframes in memory over the whole usage session.
  

## Basic usage

Assuming it's installed (see below), then in Vim hit `<leader>m` or use
`:call RunMLflow()` to start the plugin, and Vim will connect to the default
local mlflow server (localhost:5000) or the one specified in your .vimrc file.
An `__MLflow__` sidebar buffer is opened, allowing to browse the experiments
and runs and their respective attributes.  Move around with the usual Vim cursor
movement keys; select experiments and runs with `o` or `enter`.  Note the help
listing via `?` to learn more keys to select, choose, and toggle parts of the
display.  You can select some runs (across multiple experiments) and open them
in an `__MLflowRuns__` pane to allow further browsing, formatting, and comparing
of them in columns.  When hovering over a metric that was logged multiple times,
press `x` to open an ASCII plot of its history in the right-hand pane. All the
details are extensively configurable, including layout and characters used in
the display and color highlighting.


## Installation

Vim-mlflow requires:

1. Running a version of Vim that was compiled to include python3 support.
   You can verify this by looking at the output of `vim --version`.

2. Running Vim in an environment where the `mlflow` python package is installed
   (a dedicated python environment is recommended).  MLflow must be installed so
   Vim can use its python API to access the running MLflow server to which you
   connect.  So note this MLflow installation is independent of the MLflow
   server itself.

   To generate your python environment and install mlflow do:
    ```python
    python3 -m venv .venv
    source .venv/bin/activate   # on linux or macos
    pip install mlflow
    ```

3. Install `aganse/vim-mlflow` into Vim via Vundle or whatever package manager.
   For example with Vundle, add `Plugin 'aganse/vim-mlflow'` into a line in
   your .vimrc file and then run `:PluginInstall` to actually install it into
   Vim the first time.  Other package managers have similar procedures and
   should work with vim-mlflow too.

   The latest state of vim-mlflow has been tested to work with MLflow v1.30.0
   and v2.7.1.  Note it did not work with MLflow v2.1.1 (it appears that earlier
   v2 MLflow releases might have broken a few API conventions but those appear
   to have since been fixed).  An earlier MLflow version v1.26.1 doesn't work
   with this latest vim-mlfow but will with its v0.8.  If you git checkout that
   earlier version of vim-mlflow locally, you can reference it in your .vimrc
   like `Plugin 'file:///Users/aganse/Documents/src/python/vim-mlflow'`.
   Future updates of vim-mlflow will be designed to work with recent versions
   of MLflow.

   | vim-mlflow git tag | worked with mlflow version |
   | -------------------| -------------------------- |
   | v0.8               |  1.26.1                    |
   | v0.9 and since     |  1.30.0, 2.7.1             |
   | (none)             |  2.1.1                     |



## Making the animated screen-shot gif

* pip install [asciinema](https://github.com/asciinema/asciinema)
* asciinema rec demo.cast
* conduct the use-case sequence like what's seen in existing demo.cast
* install [agg](https://github.com/asciinema/agg) from
  [premade binary](https://github.com/asciinema/agg/releases/download/v1.3.0/agg-aarch64-apple-darwin)
* agg --speed 2 demo.cast demo.gif


## Configuration

A list of vim-mlflow config variables that may be of interest to set in .vimrc
(you might get away with none, or only the first one: `mlflow_tracking_uri`):
|           variable               |               description               |
| -------------------------------- | --------------------------------------- |
| `g:mlflow_tracking_uri`          | The MLFLOW_TRACKING_URI of the MLflow tracking server to connect to (default is `"http://localhost:5000"`)|
| `g:vim_mlflow_timeout`           | Timeout in float seconds if cannot access MLflow tracking server (default is 0.5)|
| `g:vim_mlflow_buffername`        | Buffername of the MLflow side pane (default is `__MLflow__`)|
| `g:vim_mlflow_runs_buffername`   | Buffername of the MLflowRuns side pane (default is `__MLflow__`)|
| `g:vim_mlflow_vside`             | Which side to open the MLflow pane on: 'left' or 'right' (default is `right`)|
| `g:vim_mlflow_hside`             | Whether to open the MLflowRuns pane 'below' or 'above' (default is `below`)|
| `g:vim_mlflow_width`             | Width of the vim-mlflow window in chars (default is 40)|
| `g:vim_mlflow_height`            | Width of the vim-mlflow window in chars (default is 10)|
| `g:vim_mlflow_expts_length`      | Number of expts to show in list (default is 8)|
| `g:vim_mlflow_runs_length`       | Number of runs to show in list (default is 8)|
| `g:vim_mlflow_viewtype`          | Show 1:activeonly, 2:deletedonly, or 3:all expts and runs (default is 1)|
| `g:vim_mlflow_show_scrollicons`  | Show the little up/down scroll arrows on expt/run lists, 1 or 0 (default is 1, ie yes show them)|
| `g:vim_mlflow_icon_useunicode`   | Allow unicode vs just ascii chars in UI, 1 or 0 (default is 1, yes allow)|
| `g:vim_mlflow_icon_vdivider`     | Default is `'─'` if `vim_mlflow_icon_useunicode` else `'-'`|
| `g:vim_mlflow_icon_scrollstop`   | Default is `'▰'` if `vim_mlflow_icon_useunicode` else `''`|
| `g:vim_mlflow_icon_scrollup`     | Default is `'▲'` if `vim_mlflow_icon_useunicode` else `'^'`|
| `g:vim_mlflow_icon_scrolldown`   | Default is `'▼'` if `vim_mlflow_icon_useunicode` else `'v'`|
| `g:vim_mlflow_icon_markrun`      | Default is `'▶'` if `vim_mlflow_icon_useunicode` else `'>'`|
| `g:vim_mlflow_color_titles`      | Element highlight color label (default is `'Statement'`)|
| `g:vim_mlflow_color_divlines`    | Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_scrollicons `| Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_selectedexpt`| Element highlight color label (default is `'String'`)|
| `g:vim_mlflow_color_selectedrun `| Element highlight color label (default is `'Number'`)|
| `g:vim_mlflow_color_help`        | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_color_markrun`     | Element highlight color label (default is `'Statement'`)|
| `g:vim_mlflow_color_hiddencol`   | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_plot_height`       | ASCII plot height in rows when graphing metric history (default `25`)|
| `g:vim_mlflow_plot_width`        | ASCII plot width in columns (default `60`)|
| `g:vim_mlflow_plot_xaxis`        | `'step'` or `'timestamp'` for metric plot x-axis (default `'step'`)|
| `g:vim_mlflow_plot_reuse_buffer` | If `1`, reuse a single `__MLflowMetricPlot__` buffer; if `0`, create sequential plot buffers (default `1`)|


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
