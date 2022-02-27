# vim-mlflow
A Vim plugin to view in Vim the tables and info one sees in an MLFlow website

## Installation

Vim-mlflow requires both installing its plugin, as well as operating in an
environment where the `mlflow` python package is installed (recommending a
dedicated python environment).  So first add the following to your .vimrc file:
`Plugin 'aganse/vim-mlflow'` (for Vundle for example - afterward you must run
`:PluginInstall` to actually install it into vim the first time).

Next generate a python environment and install mlflow (which is used for its
python API to access the running remote MLflow server to which you connect
(i.e. this is completely independent of the actual remote MLflow server itself).
Currently one must use virtualenv rather than `python3 -m venv` to generate the
python environment, so that the `activate_this.py` script is available in the
environment.  This is what the vim script uses to make mlflow and so on
accessible internally.
```python
virtualenv -p python3 .venv
```
If need to install virtualenv first, you can do via `brew install virtualenv`
on macos or `sudo apt install virtualenv` on Debian-based Linuxes.

Then enter that environment and install the python dependencies:
```python
source .venv/bin/activate   # on linux or macos
pip install mlflow
```

As this project matures, the installation process will be honed and dependencies
will be minimized or eliminated.  We'll get there!


## Usage

After installation, in future vim sessions to run vim-mlflow one must still
first enter that python virtual environment before starting vim.

When in vim, to open the MLflow page/connection, enter `:call RunMLflow()`
or use the equivalent hot-key which by default is `<leader>m`.

A few other variables that may be of interest to set in your .vimrc:
|           variable               |               description               |
| -------------------------------- | --------------------------------------- |
| `g:mlflow_tracking_uri`          | The MLFLOW_TRACKING_URI of the MLflow tracking server to connect to (default is `"http://localhost:5000"`)|
| `g:vim_mlflow_width`             | Sets the width of the vim-mlflow window |
| `g:vim_mlflow_color_titles`      | Element color customization             |
| `g:vim_mlflow_color_divlines`    | "                                       |
| `g:vim_mlflow_color_selectedexpt`| "                                       |
| `g:vim_mlflow_color_selectedrun` | "                                       |

The overall usage is to use the standard vim cursor-movement keys to move the
cursor onto lines of experiments or runs, and pressing `o` or `enter` to select
them.  Vim-mlflow requeries the MLflow server and updates the buffer accordingly.
The help screen is accessed via pressing `?`, and will show other possibilities
such as keys to toggle on/off various elements of the display, or to
requery/refresh the display (say if a new run calculation was logged).

The first-time start of vim-mlflow seems a bit slow, perhaps because of the
python environment loading, but it appears to be fine after that.
MLFlow does have a REST API equivalent to the Python API currently in use here.
However, I did not find any satisfying way of interfacing that REST API in
native vim-script (which seems like would be faster/more-generalized/preferable)
other than simply relying on other different external system dependencies
(curl,etc) which seems no different than having the Python-based dependency
implemented here (Python interprer being already compiled into vim itself).
Suggestions welcome as development continues.


## Acknowledgements plus misc refs that are useful in ongoing development

With many thanks to:
* The Writing Vim plugin in Python article by Timur Rubeko, 2017 Aug 11, at
  http://candidtim.github.io/vim/2017/08/11/write-vim-plugin-in-python.html
* Analyzing Your MLflow Data with DataFrames by Max Allen, 2019 Oct 3, at
  https://slacker.ro/2019/10/03/analyzing-your-mlflow-data-with-dataframes
* MLFlow Python API at
  https://www.mlflow.org/docs/latest/python_api/mlflow.html
* MLFlow REST API at
  https://www.mlflow.org/docs/latest/rest-api.html
* MLFlow Projects page at
  https://www.mlflow.org/docs/latest/projects.html
* The Python Interface to Vim, 2019 Dec 07, at
  https://vimhelp.org/if_pyth.txt.html#python-vim
* Alternative to execfile in Python 3, Stack Overflow, 2011 Jun 15 at
  https://stackoverflow.com/questions/6357361/alternative-to-execfile-in-python-3/6357418#6357418

Might be useful later:
* https://stackoverflow.com/questions/4189239/vim-script-input-function-that-doesnt-require-user-to-hit-enter
* https://github.com/jmcantrell/vim-virtualenv/blob/master/autoload/virtualenv.vim
* https://stackoverflow.com/questions/3881534/set-python-virtualenv-in-vim
* https://stevelosh.com/blog/2011/09/writing-vim-plugins
* https://duseev.com/articles/vim-python-pipenv
* https://blog.semanticart.com/2017/01/05/lets-write-a-basic-vim-plugin
* https://devhints.io/vimscript
* https://github.com/jceb/vim-orgmode (note orgguide.txt linked in readme; go near bottom of that page)
