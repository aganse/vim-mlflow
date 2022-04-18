# vim-mlflow
A Vim plugin to view and query in Vim the results one sees in an MLFlow website.

[![example vim-mlflow screenshot](doc/example_screen_shot.png)](doc/example_screen_shot.png)

You do need to have the mlflow package installed in the environment that vim is
run in.  Then in vim hit `<leader>m` (configurable), and it will connect to the
default local mlflow server or the one in your .vimrc file.  An `__MLflow__`
pane is opened on left (configurable), allowing to browse the experiments and
runs and their respective attributes.  You can select some number of runs and
open them in an `__MLflowRuns__` pane that allows further browsing, formatting,
and comparing of them - even runs from different experiments.


## Installation

Vim-mlflow requires:

1. Running a version of Vim that was compiled to include python3 support.
  (you can verify this by looking at the output of `vim --version`)
2. Running vim in an environment where the `mlflow` python package is installed
  (a dedicated python environment is recommended).  MLflow must be installed so
  vim can use its python API to access the running MLflow server to which you
  connect, but note this MLflow installation is independent of the actual MLflow
  server itself.
3. Understanding that vim-mlflow was originally written for an mlflow database
  running on the same local server, so it reaccesses the mlflow database (thru
  the API calls) on almost every hotkey stroke.  This can cause it to be slow to
  access a remote mlflow service on a different machine.  If demand arises this
  can be resolved in dev updates by making vim-mlflow access the mlflow APIs
  less and storing more results in memory.

To generate a python environment and install mlflow in a dedicated python
environment, use virtualenv rather than `python3 -m venv`, so that the
`activate_this.py` script is available in the environment.  This is what the
vim script uses to make mlflow accessible internally.
```python
virtualenv -p python3 .venv
```
(If need to install virtualenv first, you can do via `brew install virtualenv`
on macos or `sudo apt install virtualenv` on Debian-based Linuxes.)

Then enter that environment and install the python dependencies:
```python
source .venv/bin/activate   # on linux or macos
pip install mlflow
```

Lastly install vim-mlfow into vim via Vundle or whatever package manager:
`Plugin 'aganse/vim-mlflow'` (for Vundle for example - in which case afterward
you must run `:PluginInstall` to actually install it into vim the first time).


## Usage

In vim, to open the MLflow page/connection, enter `:call RunMLflow()`
or use the equivalent hot-key which by default is `<leader>m`.

List of vim-mlflow config variables that may be of interest to set in .vimrc:
(The first one, `mlflow_tracking_uri`, may be the only one you need!)
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

The overall usage is to use the standard vim cursor-movement keys to move the
cursor onto lines of experiments or runs, and pressing `o` or `enter` to select
them.  Vim-mlflow requeries the MLflow server and updates the buffer accordingly.
The help screen is accessed via pressing `?`, and will show other possibilities
such as keys to toggle on/off various elements of the display, or to
requery/refresh the display and open the MLflowRuns pane.


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
