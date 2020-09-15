let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

if !has("python3")
    echo "vim has to be compiled with +python3 to run this"
    finish
endif

if exists('g:vim_mlflow_plugin_loaded')
    finish
endif


python3 << EOF
import os, sys
from os.path import normpath, join
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    exec(open(activate_this).read(), {'__file__': activate_this})  # for python3

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)
import vim_mlflow
EOF

let g:vim_mlflow_plugin_loaded = 1
