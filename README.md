# vim-mlflow
[![unittests-python](https://github.com/aganse/vim-mlflow/workflows/unittests-python/badge.svg)](https://github.com/aganse/vim-mlflow/actions/workflows/unittests-python.yml)
[![unittests-vimscript](https://github.com/aganse/vim-mlflow/workflows/unittests-vimscript/badge.svg)](https://github.com/aganse/vim-mlflow/actions/workflows/unittests-vim.yml)
[![codestyle-python-flake8](https://github.com/aganse/vim-mlflow/workflows/codestyle-python-flake8/badge.svg)](https://github.com/aganse/vim-mlflow/actions/workflows/codestyle-python-flake8.yml)
[![codestyle-vimscript-vint](https://github.com/aganse/vim-mlflow/workflows/codestyle-vimscript-vint/badge.svg)](https://github.com/aganse/vim-mlflow/actions/workflows/codestyle-vimscript-vint.yml)
![licence](https://img.shields.io/badge/license-MIT-blue.svg)
![version](https://img.shields.io/badge/version-1.0.1-blue.svg)


`vim‑mlflow` is a lightweight Vim/NVim plugin that lets you browse and interact
with MLflow experiments, runs, metrics, parameters, tags, and artifacts directly
in your Vim editor.  It opens a dedicated sidebar and a detail pane so you can
explore data without leaving the terminal, even allowing you to plot metric
histories and browse non-graphical artifacts.  The plugin is written in
Vimscript with embedded Python and talks to MLflow through its Python API.
It works with both MLflow3.x and MLflow2.x ML tracking servers (but not the
GenAI traces/etc in MLflow3.x currently; feedback/demand can guide such future
steps).

[![example vim-mlflow screenshot](doc/demo_1.0.0_light.gif)](doc/demo_1.0.0_light.gif)


## TL;DR
* Must run Vim/NVim in a python environment with `mlflow` installed.
* Vim must be a compiled-with-python version (check `vim --verison` for `+python3`);
  or for NVim just install the `pynvim` package in that python environment as well.
* Put `Plugin 'aganse/vim-mlflow'` or your package manager equivalent in your
  resource file to load plugin.
* At minimum set `let g:mlflow_tracking_uri = "http://<mlflow_trk_svr_host>:<port>"`
  in your resource file to your MLflow tracking server.  Other options listed below.
* Press `\m` (leader-key and `m`) to start the plugin, and press `?` in there to
  check the help listing for other keys.  Navigate with the standard vim movement
  keys, and "open" various items via `o` or `<enter>`.


## Installation

#### 1. Check that your Vim supports python3:
- In Vim: `vim --version | grep +python3` (if no +python3 line is found, you
  must install a Vim build compiled with Python3.)
- In NVim you're good to go as long as you install pynvim in your python env
  down in #3.
- Tested successfully on Vim 8.2+ and NVim v0.11.5, with Python3.10+.

#### 2. Highly recommended to create/use a python virtual environment:
- `python3 -m venv .venv`
- `source .venv/bin/activate  # syntax for linux/mac`

#### 3. Install the `mlflow` Python package (and also `pynvim` for Nvim):
- `pip install mlflow` (in both Vim and NVim)
- In NVim you also need this package in your env to support the python:
  `pip install pynvim`

#### 4. Load Vim-mlflow in your Vim/NVim resource file:
- Add the plugin to your plugin manager, e.g. using Vundle add
  `Plugin 'aganse/vim-mlflow'` to your resource file and run `:PluginInstall`.
- Or could do manually, e.g. in NVim's `~/.config/nvim/init.vim` could load
  via: `set runtimepath+=/Users/aganse/Documents/src/python/vim-mlflow`

#### 5. Set your config settings in your Vim/NVim resource file:
- Set your MLflow tracking URI.  Fyi the default is `http://localhost:5000`,
  which may be relevant for a simple local test setup, but often you'll have
  some other host and port to set:
  `let g:mlflow_tracking_uri = "http://<mlflow_trk_svr_host>:<port>"`

- The Configuration section has quite a list of settings (colors, characters,
  sizing, etc) that can be customized.
  
- For NVim you may need to set `setlocal nowrap` in your resource file - see
  last Troubleshooting tip below regarding line-wrap default in NVim affecting
  content layout.


## Usage
* Ensure you're in your python environment with MLflow before starting Vim.
* Press `\m` to start vim-mlflow (default setting, ie leader-key and m. or can
  use `:call RunMLflow()`).  You can update that leader/key mapping via
  `nnoremap <leader>m :call RunMLflow()<CR>`.
* Vim-mlflow opens a sidebar (`__MLflow__`) that lists all experiments on the
  connected MLflow server.
* Navigate the cursor around with the standard vim movement keys, and "open"
  various items via `o` or `<enter>` key.
* Select experiments to show their respective lists of runs; drill into runs to
  view metrics, parameters, tags, and artifacts. View ASCII plots of metric
  histories, and text artifacts inline.
* Open a run comparison pane (`__MLflowRuns__`) to compare metrics across
  multiple selected runs in multiple experiments.
* Press `?` in the sidebar for a full help listing of the keys map.


## Configuration
Only `g:mlflow_tracking_uri` is required to be set by user (e.g. in resource file).
But a typical small set of vim-mlflow config variables that one might set is:
```vim
" Vim-mlflow settings
let g:mlflow_tracking_uri = "http://localhost:5000"  " running locally or via ssh-tunnel
let g:vim_mlflow_icon_useunicode = 1  " default 0 value uses ascii chars instead
let g:vim_mlflow_width = get(g:, 'vim_mlflow_width', 50)  " width of mlflow window
let g:vim_mlflow_expts_length = 10  " experiments to show at a time
let g:vim_mlflow_runs_length = 15   " runs to show at a time
```

By default Vim-mlflow uses standard color groups like "Comment" and "Statement"
to color its components so that whatever your colorscheme is it should "just
work" in vim-mlflow.  (E.g. the animated GIF above used
[PaperColor](https://github.com/vim-scripts/PaperColor.vim) colorscheme;
see also its [dark-mode equivalent animated GIF](doc/demo_1.0.0_dark.gif)).
But all details can be changed, per listing below.
With no configuration parameters set, ascii characters with no color are used.

See the [full listing of vim-mlflow config variables](doc/configuration_params.md)
that may be of interest to set in your resource file.


## Troubleshooting
- The sidebar may be slow on high-latency MLflow connections because each
  refresh starts a short-lived Python process and re-queries MLflow.
  Performance seems fine when Vim runs close to the tracking server; running
  all components in AWS within same region, it has worked well for our team.
  On slower links, increasing `g:vim_mlflow_timeout` may help.  A future version
  could use a persistent Python process to reduce queries if necessary, but so
  far this has not been a common enough concern.
- Unicode icons require a font that includes box-drawing characters.  Set
  `g:vim_mlflow_icon_useunicode = 0` if glyphs look broken as the simple quick
  fix, and also note there are config vars to change individual icon characters.
- Text artifacts (`*.txt`, `*.json`, `*.yaml`, `MLmodel`) open directly in the
  plugin.  Binary artifacts are listed but cannot be opened in the plugin.
- If the plugin fails to load in classic Vim, verify that Vim supports Python
  (vim --version) and that mlflow is importable in Vim’s Python environment
  (:py3 import mlflow). In Neovim, also ensure pynvim is installed.
- In NVim if the layout seems screwy, check step 5 above in Installation
  regarding `nowrap`.
- Neovim enables line wrapping by default, which can break table layouts in
  this plugin. Adding `setlocal nowrap` fixes this globally. The issue is most
  noticeable in the MLflowRuns window (opened with R), which displays many
  columns.


## Contributing
Contributions are welcome; just note this project is maintained on a best-effort
basis by a single maintainer (Andy Ganse) alongside other commitments, and so
focused on long-term maintainability more than rapid feature growth.  Bug fixes,
documentation improvements, and small, well-scoped enhancements are the most
likely to be accepted.  Feature requests may be declined if they significantly
increase complexity, maintenance burden, or diverge from the project’s stated
scope.  Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening issues or
pull requests, and note that response and review times may not be fast.

#### Dev tools to be aware of when contributing
This repo has unittests and codestyle checks, implemented in both CI workflows
and also available locally via the following Makefile calls.  To run these you
need a few more packages in your Python environment than when just using the
plugin as above.  So for dev purposes after entering your Python environment 
(e.g. `source .venv/bin/activate`) run `make dev-env` which will install the
list of packages in dev-requirements.txt.  Then you can run the following to
confirm they pass before submitting a PR for review (and to ease passing the
CI workflows):
- `make unittests` runs Vimscript unittests in both Vim and Neovim, and also
  the Python unittests.
- `make codestyle` lints the Vimscript in `plugin/` with `vint` and the
  Python in `python/` with `flake8`.


## Legacy/older versions
Legacy/older versions of this plugin can be accessed by git checking out an
earlier version locally, and then referencing it in your .vimrc (for classic
Vim like `Plugin 'file:///my/path/to/python/vim-mlflow'`.
Or similarly you can set that path in your runtimepath in NVim (without the
`file://`).
That said, it's recommended to use >= v1.0.0 - that's the first "official"
release (we'll just keep adding to this table as more releases come out).

|  vim-mlflow git tag  | tested with mlflow version | tested with vim version |
| ---------------------| -------------------------- | ----------------------- |
| v0.8                 |  1.26.1                    | vim 8.2                 |
| v0.9                 |  1.30.0, 2.7.1             | vim 8.2                 |
| v1.0.0 (this version)|  2.12.0, 2.19.0, 3.6.0     | vim 9.1, nvim v0.11.5   |


## Related repos by aganse
Vim-mlflow is part of a group of tools that you might find useful together (but
all are separate tools that can be used independently).  In particular the
following two tools allow to populate test contents into a temporary MLflow
tracking server for dev/test purposes - they're the contents seen in screencast
above:
* [aganse/docker_mlflow_db](https://github.com/aganse/docker_mlflow_db):
    ready-to-run MLflow server with PostgreSQL, AWS S3, Nginx
* [aganse/py_torch_gpu_dock_mlflow](https://github.com/aganse/py_torch_gpu_dock_mlflow):
    ready-to-run Python/PyTorch/MLflow-Projects setup to train models on GPU


## Making the animated screen-shot gif
* Install [rust](https://rust-lang.org/tools/install) (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
* Install [asciinema](https://github.com/asciinema/asciinema) (`cargo install --locked --git https://github.com/asciinema/asciinema`)
* `~/.cargo/bin/asciinema rec demo.cast  # start recording terminal screen to file`
* Manually conduct the usage sequence to record, which gets saved to file; ctrl-D to exit/end when done.
* Install [agg](https://github.com/asciinema/agg) (`cargo install --git https://github.com/asciinema/agg`)
* `~/.cargo/bin/agg --speed 2 demo.cast demo.gif  # convert the asciinema cast to animated gif`


## Acknowledgements
With many thanks to:
* "Writing a Vim plugin in Python" article by Timur Rubeko, 2017 Aug 11, at
  http://candidtim.github.io/vim/2017/08/11/write-vim-plugin-in-python.html
* "Analyzing Your MLflow Data with DataFrames" by Max Allen, 2019 Oct 3, at
  https://www.databricks.com/blog/2019/10/03/analyzing-your-mlflow-data-with-dataframes.html
* The Python Interface to Vim, 2019 Dec 07, at
  https://vimhelp.org/if_pyth.txt.html#python-vim
* MLFlow Python API at
  https://www.mlflow.org/docs/latest/python_api/mlflow.html
