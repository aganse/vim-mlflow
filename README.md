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
source .venv/bin/activate   # on linux
pip install mlflow
```

As this project matures, the installation process will be honed and dependencies
will be minimized or eliminated.  We'll get there!


## Usage

After installation, in future vim sessions to run vim-mlflow one must still
first enter that python virtual environment before starting vim.

When in vim, to open the MLflow page/connection, enter:
```
:call RunMLflow()
```
or use the equivalent hot-key which by default is `<leader>m`.
The default MLFLOW_TRACKING_URI is "http://localhost:5000", but this can be
set to whatever desired URI by setting `g:mlflow_tracking_uri` (in your
.vimrc file for example).

A few other variables that may be of interest:
`g:vim_mlflow_width` : sets the width of the vim-mlflow window.
Element color customization (they have defaults based on arbitrary syntax highlighting colors):
`g:vim_mlflow_color_titles`
`g:vim_mlflow_color_divlines`
`g:vim_mlflow_color_selectedexpt`
`g:vim_mlflow_color_selectedrun`

The next step is to add selection of elements in the experiment or run lists to
auto-refresh the other lists/outputs as follows the respective quantities.
Also, initialization is awfully slow, perhaps because of the python environment
loading?  We'll look into options for that too.



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


Add reference to this plugin into .vimrc file:
Plugin 'file:///Users/aganse/Documents/src/python/vim-mlflow'

This plugin relies on vim being run in a python environment that has mlflow
installed.

Might be useful later:
* https://github.com/jmcantrell/vim-virtualenv/blob/master/autoload/virtualenv.vim
* https://stackoverflow.com/questions/3881534/set-python-virtualenv-in-vim
* https://stevelosh.com/blog/2011/09/writing-vim-plugins
* https://duseev.com/articles/vim-python-pipenv
* https://blog.semanticart.com/2017/01/05/lets-write-a-basic-vim-plugin  <<--- instrumental
* https://devhints.io/vimscript  <<--- instrumental
* https://github.com/jceb/vim-orgmode
   (note orgguide.txt linked in readme; near bottom of that page note
    sections "Structure and Source Code", "Writing a plugin" (which is about
    writing an OrgMode plugin, not vim plugin per se), "Keybindings", and
    "Creating Tests Cases")
