# vim-mlflow
A Vim plugin to view in Vim the tables and info one sees in an MLFlow website

Need to use virtualenv rather than `python3 -m venv` to generate python
environment so the `activate_this.py` script is available in the environment.
This is what the vim script uses to make mlflow and so on accessible internally.
```python
virtualenv -p python3 .venv
```
If need to install virtualenv, can do `brew install virtualenv` on macos or
`sudo apt install virtualenv` on Debian-based Linuxes.

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
