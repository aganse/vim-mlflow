let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

nnoremap <buffer> <localleader>m :call RunMLflow()<cr>
if ! exists('g:mlflow_tracking_uri')
    let g:mlflow_tracking_uri = "http://localhost:5000"
endif

if !has("python3")
    echo "Error: vim must be compiled with +python3 to run the vim-mlflow plugin."
    finish
endif

" Only load vim-mlflow plugin once
if exists('g:vim_mlflow_plugin_loaded')
    finish
endif


function! RunMLflow()
  let l:results = MainPageMLflow()

  " Create a split with a meaningful name
  let l:name = '__MLflow__'
  let g:vim_mlflow_width = 40

  if bufwinnr(l:name) == -1
      " Open a new split
      execute 'vsplit ' . l:name
      execute 'vertical resize ' . g:vim_mlflow_width 
  else
      " Focus the existing window
      execute bufwinnr(l:name) . 'wincmd w'
  endif

  " Clear out existing content
  normal! gg"_dG

  " Don't prompt to save the buffer
  set buftype=nofile

  " Insert the results.
  call append(0, l:results)

  " Colorize the contents
  set nonumber
  call ColorizeMLflowBuffer()

endfunction


function! ColorizeMLflowBuffer()
    let g:vim_mlflow_color_titles = "pythonStatement"
    let g:vim_mlflow_color_divlines = "pythonFunction"
    let g:vim_mlflow_color_selectedexpt = "pythonString"
    let g:vim_mlflow_color_selectedrun = "pythonNumber"
    call matchadd(g:vim_mlflow_color_titles, "Experiments:")
    call matchadd(g:vim_mlflow_color_titles, "Runs in expt .*:")
    call matchadd(g:vim_mlflow_color_titles, "Params in run .*:")
    call matchadd(g:vim_mlflow_color_titles, "Metrics in run .*:")
    call matchadd(g:vim_mlflow_color_titles, "Tags in run .*:")
    call matchadd(g:vim_mlflow_color_divlines, "------*")
    call matchadd(g:vim_mlflow_color_selectedexpt, "\#".s:current_exptid."\:")
    call matchadd(g:vim_mlflow_color_selectedrun, "\#".s:current_runid[0:4])
endfunction


function! MainPageMLflow()
let s:current_exptid = "0"
let s:current_runid = "c3ab61002e3e40d3b421fc2b390497e0"

python3 << EOF
import os, sys
from os.path import normpath, join
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    exec(open(activate_this).read(), {'__file__': activate_this})

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

import vim_mlflow  # this import must be after entering python env above
mlflowmain = vim_mlflow.getMainPageMLflow(vim.eval('g:mlflow_tracking_uri'))
EOF

let g:vim_mlflow_plugin_loaded = 1
let mlflowmain = py3eval('mlflowmain')
return mlflowmain
endfunction
