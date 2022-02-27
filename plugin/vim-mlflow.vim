let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

nnoremap <buffer> <localleader>m :call RunMLflow()<cr>
if ! exists('g:mlflow_tracking_uri')
    let g:mlflow_tracking_uri = 'http://localhost:5000'
endif

if !has('python3')
    echo 'Error: vim must be compiled with +python3 to run the vim-mlflow plugin.'
    finish
endif

" Only load vim-mlflow plugin once
if exists('g:vim_mlflow_plugin_loaded')
    finish
endif


function! RunMLflow()

  " Set variables defining default/startup behavior
  let l:name = '__MLflow__'
  let g:vim_mlflow_width = 40
  let s:help_msg_is_showing = 0
  let s:current_exptid = ''  " empty string means show '1st expt'
  let s:current_runid = ''   " empty string means show '1st run'
  let s:expt_hi = ''
  let s:params_are_showing = 1
  let s:metrics_are_showing = 1
  let s:tags_are_showing = 1
  let s:expts_first_idx = 0
  let g:vim_mlflow_expts_length = 8
  let s:runs_first_idx = 0
  let g:vim_mlflow_runs_length = 8

  if bufwinnr(l:name) == -1
      " Open a new split
      execute 'vsplit ' . l:name
      execute 'vertical resize ' . g:vim_mlflow_width 
  else
      " Focus the existing window
      execute bufwinnr(l:name) . 'wincmd w'
  endif

  " Set buffer properties: no line#s, don't prompt to save
  set nonumber
  set buftype=nofile

  " Initial query/draw of MLflow content
  call RefreshMLflowBuffer()
  normal! 1G

  " Map certain key input to vim-mlflow features within buffer
  nmap <buffer>  ?    :call ListHelpMsg()<CR>
  nmap <buffer>  <CR> :call RefreshMLflowBuffer()<CR>
  nmap <buffer>  o    :call RefreshMLflowBuffer()<CR>
  nmap <buffer>  r    :call RefreshMLflowBuffer()<CR>
  nmap <buffer>  p    :call ToggleParamsDisplay()<CR>
  nmap <buffer>  m    :call ToggleMetricsDisplay()<CR>
  nmap <buffer>  t    :call ToggleTagsDisplay()<CR>

endfunction


" Assign current expt or run under cursor into script variable
function! AssignExptRunFromCurpos(curpos)
  let l:currentLine = getline(a:curpos[1])

  " Not clear why couldn't get () to work in regexp in matchstr below;
  " maybe some issue with vim 'magic'; with () then substitute unnecesary!
  let l:expt = substitute(matchstr(l:currentLine, '\m\#[0-9]\{1,4\}\:'), '[\#\:]', '', 'g')
  let l:run = substitute(matchstr(l:currentLine, '\m\#[0-9a-fA-F]\{5\}\:'), '[\#\:]', '', 'g')

  if l:expt != ''
    let s:current_exptid = l:expt
    let s:current_runid = ''
  endif
  if l:run != ''
    let s:current_runid = l:run
  endif
  call cursor(1, 1)
endfunction


" Requery MLflow content and update buffer
function! RefreshMLflowBuffer()
  " let wordUnderCursor = expand("<cword>")  " useful later
  let l:curpos = getpos('.')

  " Update current expt or run if specified in input arg
  call AssignExptRunFromCurpos(l:curpos)

  " Clear out existing content
  normal! gg"_dG

  " Insert the results.
  let l:results = MainPageMLflow()
  call append(0, l:results)

  " Colorize the contents
  call ColorizeMLflowBuffer()

  " Replace the cursor position
  call setpos('.', l:curpos)

  redraw
endfunction


function! ColorizeMLflowBuffer()
    let g:vim_mlflow_color_titles = 'pythonStatement'
    let g:vim_mlflow_color_divlines = 'pythonFunction'
    let g:vim_mlflow_color_selectedexpt = 'pythonString'
    let g:vim_mlflow_color_selectedrun = 'pythonNumber'
    let g:vim_mlflow_color_help= 'pythonComment'
    call matchadd(g:vim_mlflow_color_titles, '^.*Experiments:')
    call matchadd(g:vim_mlflow_color_titles, '^.*Runs in expt .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Params in run .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Metrics in run .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Tags in run .*:')
    call matchadd(g:vim_mlflow_color_divlines, '------*')
    call matchadd(g:vim_mlflow_color_help, '^".*')
    if s:expt_hi != ''
      call matchdelete(s:expt_hi)
      call matchdelete(s:run_hi)
    endif
    let s:expt_hi = matchadd(g:vim_mlflow_color_selectedexpt, '\#'.s:current_exptid.'\:')
    let s:run_hi = matchadd(g:vim_mlflow_color_selectedrun, '\#'.s:current_runid[0:4].'\:')
endfunction


function! ToggleParamsDisplay()
  if ! s:params_are_showing
    let s:params_are_showing = 1
  else
    let s:params_are_showing = 0
  endif
  call RefreshMLflowBuffer()
endfunction


function! ToggleMetricsDisplay()
  if ! s:metrics_are_showing
    let s:metrics_are_showing = 1
  else
    let s:metrics_are_showing = 0
  endif
  call RefreshMLflowBuffer()
endfunction


function! ToggleTagsDisplay()
  if ! s:tags_are_showing
    let s:tags_are_showing = 1
  else
    let s:tags_are_showing = 0
  endif
  call RefreshMLflowBuffer()
endfunction


function! ListHelpMsg()
  let l:helptext = [
    \'Vim-MLflow',
    \'" ------------------------',
    \'" ? :  toggle help listing',
    \'" o :  enter expt or run under cursor',
    \'" <enter> :   "    "    "',
    \'" r :  requery MLflow display',
    \'" A :  cycle Active/Deleted/All view',
    \'" N :  scroll down list under cursor',
    \'" P :  scroll up list under cursor',
    \'" p :  toggle display of parameters',
    \'" m :  toggle display of metrics',
    \'" t :  toggle display of tags',
    \'" ------------------------',
    \'" Press ? to remove help',
    \]
  if ! s:help_msg_is_showing
    " temporarily remove 'press ? for help listing' message
    normal! 1G2dd
    call append(line('^'), l:helptext)
    normal! 1G
    let s:help_msg_is_showing = 1
  else
    execute "normal! 1G". len(l:helptext) . "dd"
    call append(line('^'), '" Press ? for help')
    call append(line('^'), 'Vim-MLflow')
    let s:help_msg_is_showing = 0
  endif
  redraw

endfunction


function! MainPageMLflow()

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
