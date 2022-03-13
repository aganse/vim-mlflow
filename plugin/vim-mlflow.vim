let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if !has('python3')
    echo 'Error: vim must be compiled with +python3 to run the vim-mlflow plugin.'
    finish
endif
" Only load vim-mlflow plugin once
if exists('g:vim_mlflow_plugin_loaded')
    finish
endif
nnoremap <buffer> <localleader>m :call RunMLflow()<cr>


function! SetDefaults()
    " Set the defaults for all the user-specifiable options
    let g:mlflow_tracking_uri = get(g:, 'mlflow_tracking_uri', 'http://localhost:5000')
    let g:vim_mlflow_timeout = get(g:, 'vim_mlflow_timeout', 0.5)  " seconds
    let g:vim_mlflow_buffername = get(g:, 'vim_mlflow_buffername', '__MLflow__')
    let g:vim_mlflow_runs_buffername = get(g:, 'vim_mlflow_runs_buffername', '__MLflowRuns__')
    let g:vim_mlflow_vside = get(g:, 'vim_mlflow_vside', 'left')  " 'left' or 'right'
    let g:vim_mlflow_hside = get(g:, 'vim_mlflow_hside', 'below')  " 'below' or 'above'
    let g:vim_mlflow_width = get(g:, 'vim_mlflow_width', 40)
    let g:vim_mlflow_height = get(g:, 'vim_mlflow_height', 12)
    let g:vim_mlflow_expts_length = get(g:, 'vim_mlflow_expts_length', 8)
    let g:vim_mlflow_runs_length = get(g:, 'vim_mlflow_runs_length', 8)
    let g:vim_mlflow_viewtype = get(g:, 'vim_mlflow_viewtype', 1)  " 1:activeonly, 2:deletedonly, 3:all
    let g:vim_mlflow_show_scrollicons = get(g:, 'vim_mlflow_show_scrollicons', 1)
    let g:vim_mlflow_icon_useunicode = get(g:, 'vim_mlflow_icon_useunicode', 0)
    if g:vim_mlflow_icon_useunicode 
        let g:vim_mlflow_icon_vdivider = get(g:, 'vim_mlflow_icon_vdivider', '─')
        let g:vim_mlflow_icon_scrollstop = get(g:, 'vim_mlflow_icon_scrollstop', '▰')
        let g:vim_mlflow_icon_scrollup = get(g:, 'vim_mlflow_icon_scrollup', '▲')
        let g:vim_mlflow_icon_scrolldown = get(g:, 'vim_mlflow_icon_scrolldown', '▼')
        let g:vim_mlflow_icon_markrun = get(g:, 'vim_mlflow_icon_markrun', '▶')
    else
        let g:vim_mlflow_icon_vdivider = get(g:, 'vim_mlflow_icon_vdivider', '-')
        let g:vim_mlflow_icon_scrollstop = get(g:, 'vim_mlflow_icon_scrollstop', '')
        let g:vim_mlflow_icon_scrollup = get(g:, 'vim_mlflow_icon_scrollup', '^')
        let g:vim_mlflow_icon_scrolldown = get(g:, 'vim_mlflow_icon_scrolldown', 'v')
        let g:vim_mlflow_icon_markrun = get(g:, 'vim_mlflow_icon_markrun', '>')
    endif
endfunction


function! RunMLflow()
    let s:current_exptid = ''  " empty string means show '1st expt'
    let s:current_runid = ''   " empty string means show '1st run'
    let s:expt_hi = ''
    let s:expts_first_idx = 0
    let s:runs_first_idx = 0
    let s:help_msg_is_showing = 0
    let s:runhelp_msg_is_showing = 0
    let s:params_are_showing = 1
    let s:metrics_are_showing = 1
    let s:tags_are_showing = 1
    let s:markruns_list = []
    let s:hiddencols_list = []
  
    " Set the defaults for all the user-specifiable options
    call SetDefaults()
  
    if bufwinnr(g:vim_mlflow_buffername) == -1
        " Open a new split on specified side
        if g:vim_mlflow_vside == 'left'
            execute 'lefta vsplit ' . g:vim_mlflow_buffername
        elseif g:vim_mlflow_vside == 'right'
            execute 'rightb vsplit ' . g:vim_mlflow_buffername
        else
            echo 'unrecognized value for g:vim_mlflow_vside = ' . g:vim_mlflow_vside
        endif
        execute 'vertical resize ' . g:vim_mlflow_width 
    else
        " Focus the existing window
        execute bufwinnr(g:vim_mlflow_buffername) . 'wincmd w'
    endif
  
    " Set buffer properties: no line#s, don't prompt to save
    set nonumber
    set buftype=nofile
  
    " Initial query/draw of MLflow content
    call RefreshMLflowBuffer(1)
    normal! 1G
  
    " Map certain key input to vim-mlflow features within buffer
    nmap <buffer>  ?     :call ListHelpMsg()<CR>
    nmap <buffer>  <CR>  :call RefreshMLflowBuffer(1)<CR>
    nmap <buffer>  <space>  :call MarkRun()<CR>
    nmap <buffer>  o     :call RefreshMLflowBuffer(1)<CR>
    nmap <buffer>  r     :call RefreshMLflowBuffer(0)<CR>
    nmap <buffer>  R     :call OpenRunsWindow()<CR>
    nmap <buffer>  <C-p> :call ToggleParamsDisplay()<CR>
    nmap <buffer>  <C-m> :call ToggleMetricsDisplay()<CR>
    nmap <buffer>  <C-t> :call ToggleTagsDisplay()<CR>
    nmap <buffer>  A     :call CycleActiveDeletedAll()<CR>
    nmap <buffer>  n     :call ScrollListDown()<CR>
    nmap <buffer>  p     :call ScrollListUp()<CR>
    nmap <buffer>  N     :call ScrollListBtm()<CR>
    nmap <buffer>  P     :call ScrollListTop()<CR>

endfunction


function! OpenRunsWindow()
  
    if bufwinnr(g:vim_mlflow_runs_buffername) == -1
        " Open a new split on specified side
        if g:vim_mlflow_hside == 'below'
            execute 'botright split ' . g:vim_mlflow_runs_buffername
        elseif g:vim_mlflow_hside == 'above'
            execute 'topleft split ' . g:vim_mlflow_runs_buffername
        else
            echo 'unrecognized value for g:vim_mlflow_hside = ' . g:vim_mlflow_hside
        endif
        execute 'resize ' . g:vim_mlflow_height
    else
        " Focus the existing window
        execute bufwinnr(g:vim_mlflow_runs_buffername) . 'wincmd w'
    endif
  
    " Set buffer properties: no line#s, don't prompt to save
    set nonumber
    set buftype=nofile
  
    " Initial query/draw of MLflow content
    call RefreshRunsBuffer(1)
    normal! 1G
  
    " Map certain key input to vim-mlflow features within buffer
    nmap <buffer>  ?     :call RunsListHelpMsg()<CR>
    nmap <buffer>  R     :call OpenRunsWindow()<CR>

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
        let s:runs_first_idx = 0
    endif
    if l:run != ''
        let s:current_runid = l:run
    endif
    call cursor(1, 1)
endfunction


" Requery MLflow content and update buffer
function! RefreshMLflowBuffer(doassign, ...)
    " let wordUnderCursor = expand("<cword>")  " useful later
    let l:curpos = get(a:, 1)
    if ! exists(l:curpos)
        let l:curpos = getpos('.')
    endif
  
    " Update current expt or run if specified in input arg
    if a:doassign
        call AssignExptRunFromCurpos(l:curpos)
    endif
  
    " Clear out existing content
    normal! gg"_dG
  
    " Insert the results.
    let l:view = winsaveview()
    let l:results = MainPageMLflow()
    call append(0, l:results)
    call winrestview(l:view)
  
    " Colorize the contents
    call ColorizeMLflowBuffer()
  
    " Replace the cursor position
    call setpos('.', l:curpos)
  
    redraw
endfunction


" Requery MLflow runs content and update buffer
function! RefreshRunsBuffer(doassign, ...)
    " let wordUnderCursor = expand("<cword>")  " useful later
    let l:curpos = get(a:, 1)
    if ! exists(l:curpos)
        let l:curpos = getpos('.')
    endif
  
    " Update current expt or run if specified in input arg
    "if a:doassign
    "    call AssignExptRunFromCurpos(l:curpos)
    "endif
  
    " Clear out existing content
    normal! gg"_dG
  
    " Insert the results.
    let l:view = winsaveview()
    let l:results = RunsPageMLflow()
    call append(0, l:results)
    call winrestview(l:view)
  
    " Colorize the contents
    call ColorizeRunsBuffer()
  
    " Replace the cursor position
    call setpos('.', l:curpos)
  
    redraw
endfunction


function! ColorizeRunsBuffer()
    let g:vim_mlflow_color_titles = 'pythonStatement'
    let g:vim_mlflow_color_divlines = 'vimParenSep'  " 'pythonComment'
    let g:vim_mlflow_color_scrollicons = 'vimParenSep'  " 'pythonComment'
    let g:vim_mlflow_color_selectedexpt = 'pythonString'
    let g:vim_mlflow_color_selectedrun = 'pythonNumber'
    let g:vim_mlflow_color_help= 'pythonComment'
    let g:vim_mlflow_color_markrun= 'pythonStatement'
    call matchadd(g:vim_mlflow_color_titles, 'expt_id.*$')
    if g:vim_mlflow_icon_vdivider != ''
        call matchadd(g:vim_mlflow_color_divlines, repeat(g:vim_mlflow_icon_vdivider, 4).'*')
    endif
    call matchadd(g:vim_mlflow_color_help, '^".*')
    " if s:markrun_expt_hi != ''
    "     call matchdelete(s:markrun_expt_hi)
    "     call matchdelete(s:markrun_run_hi)
    " endif
    " let s:markrun_expt_hi = matchadd(g:vim_mlflow_color_selectedexpt, '\#'.s:current_exptid.' ')
    " let s:markrun_run_hi = matchadd(g:vim_mlflow_color_selectedrun, '\#'.s:current_runid[0:4].' ')
endfunction


function! ColorizeMLflowBuffer()
    let g:vim_mlflow_color_titles = 'pythonStatement'
    let g:vim_mlflow_color_divlines = 'vimParenSep'  " 'pythonComment'
    let g:vim_mlflow_color_scrollicons = 'vimParenSep'  " 'pythonComment'
    let g:vim_mlflow_color_selectedexpt = 'pythonString'
    let g:vim_mlflow_color_selectedrun = 'pythonNumber'
    let g:vim_mlflow_color_help= 'pythonComment'
    let g:vim_mlflow_color_markrun= 'pythonStatement'
    call matchadd(g:vim_mlflow_color_titles, '^.*Experiments:')
    call matchadd(g:vim_mlflow_color_titles, '^.*Runs in expt .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Params in run .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Metrics in run .*:')
    call matchadd(g:vim_mlflow_color_titles, 'Tags in run .*:')
    if g:vim_mlflow_icon_vdivider != ''
        call matchadd(g:vim_mlflow_color_divlines, repeat(g:vim_mlflow_icon_vdivider, 4).'*')
    endif
    if g:vim_mlflow_icon_scrollstop != ''
        call matchadd(g:vim_mlflow_color_scrollicons, '^'.g:vim_mlflow_icon_scrollstop)
    endif
    call matchadd(g:vim_mlflow_color_scrollicons, '^'.g:vim_mlflow_icon_scrollup)
    call matchadd(g:vim_mlflow_color_scrollicons, '^'.g:vim_mlflow_icon_scrolldown)
    call matchadd(g:vim_mlflow_color_help, '^".*')
    call matchadd(g:vim_mlflow_color_markrun, '^'.g:vim_mlflow_icon_markrun.'.*$')
    if s:expt_hi != ''
        call matchdelete(s:expt_hi)
        call matchdelete(s:run_hi)
    endif
    let s:expt_hi = matchadd(g:vim_mlflow_color_selectedexpt, '\#'.s:current_exptid.'\:')
    let s:run_hi = matchadd(g:vim_mlflow_color_selectedrun, '\#'.s:current_runid[0:4].'\:')
endfunction


function! CycleActiveDeletedAll()
    " Cycle over values 1-3 (noting that % outputs 0-2)
    " which correspond to states Active, Deleted, and All
    " for both Experiments and Runs simultaneously:
    let g:vim_mlflow_viewtype = (g:vim_mlflow_viewtype%3)+1
    call RefreshMLflowBuffer(1)
endfunction


function! MarkRun()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    let s:actual_expts_length = min([g:vim_mlflow_expts_length, s:num_expts])
    let s:actual_runs_length = min([g:vim_mlflow_runs_length, s:num_runs])
    if l:curpos[1]>l:top_to_expts+s:actual_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+s:actual_expts_length+l:expts_to_runs+s:actual_runs_length
        let l:currentLine = getline(l:curpos[1])
        let l:runid5 = substitute(matchstr(l:currentLine, '\m\#[0-9a-fA-F]\{5\}\:'), '[\#\:]', '', 'g')
        if l:runid5 != ''
            if index(s:markruns_list, l:runid5) >= 0  " If item is in the list.
                call remove(s:markruns_list, index(s:markruns_list, l:runid5))
            else
                call add(s:markruns_list, l:runid5)
            endif
        endif
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ScrollListDown()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    let s:actual_expts_length = min([g:vim_mlflow_expts_length, s:num_expts])
    let s:actual_runs_length = min([g:vim_mlflow_runs_length, s:num_runs])
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+s:actual_expts_length &&
     \ s:expts_first_idx < s:num_expts-s:actual_expts_length
        let s:expts_first_idx = s:expts_first_idx + 1  "v:count1
    elseif l:curpos[1]>l:top_to_expts+s:actual_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+s:actual_expts_length+l:expts_to_runs+s:actual_runs_length &&
     \     s:runs_first_idx < s:num_runs-s:actual_runs_length
        let s:runs_first_idx = s:runs_first_idx + 1  "v:count1
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ScrollListUp()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    let s:actual_expts_length = min([g:vim_mlflow_expts_length, s:num_expts])
    let s:actual_runs_length = min([g:vim_mlflow_runs_length, s:num_runs])
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+s:actual_expts_length &&
     \ s:expts_first_idx > 0
        let s:expts_first_idx = s:expts_first_idx - 1  "v:count1
    elseif l:curpos[1]>l:top_to_expts+s:actual_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+s:actual_expts_length+l:expts_to_runs+s:actual_runs_length &&
     \     s:runs_first_idx > 0
        let s:runs_first_idx = s:runs_first_idx - 1  "v:count1
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ScrollListBtm()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+g:vim_mlflow_expts_length &&
     \ s:expts_first_idx < s:num_expts-1
        let s:expts_first_idx = max([0, s:num_expts-g:vim_mlflow_expts_length])
    elseif l:curpos[1]>l:top_to_expts+g:vim_mlflow_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+g:vim_mlflow_expts_length+l:expts_to_runs+g:vim_mlflow_expts_length &&
     \     s:runs_first_idx < s:num_runs-1
        "let s:runs_first_idx = s:num_runs-1
        let s:runs_first_idx = max([0, s:num_runs-g:vim_mlflow_runs_length])
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ScrollListTop()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+g:vim_mlflow_expts_length &&
     \ s:expts_first_idx > 0
        let s:expts_first_idx = 0
    elseif l:curpos[1]>l:top_to_expts+g:vim_mlflow_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+g:vim_mlflow_expts_length+l:expts_to_runs+g:vim_mlflow_expts_length &&
     \     s:runs_first_idx > 0
        let s:runs_first_idx = 0
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ToggleParamsDisplay()
    if ! s:params_are_showing
        let s:params_are_showing = 1
    else
        let s:params_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleMetricsDisplay()
    if ! s:metrics_are_showing
        let s:metrics_are_showing = 1
    else
        let s:metrics_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleTagsDisplay()
    if ! s:tags_are_showing
        let s:tags_are_showing = 1
    else
        let s:tags_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ListHelpMsg()
    let l:helptext = [
        \'Vim-MLflow',
        \'" ------------------------',
        \'" ?  :  toggle help listing',
        \'" r  :  requery MLflow display',
        \'" o  :  enter expt or run under cursor',
        \'" <enter> :   "    "    "',
        \'" <space> :  mark run under cursor',
        \'" R  :  open marked-runs buffer',
        \'" A  :  cycle Active/Deleted/All view',
        \'" n  :  scroll down list under cursor',
        \'" p  :  scroll up list under cursor',
        \'" N  :  scroll to bottom of list',
        \'" P  :  scroll to top of list',
        \'" ^p :  toggle display of parameters',
        \'" ^m :  toggle display of metrics',
        \'" ^t :  toggle display of tags',
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


function! RunsListHelpMsg()
    let l:helptext = [
        \'Vim-MLflow Marked Runs',
        \'" ------------------------',
        \'" ?  :  toggle help listing',
        \'" R  :  requery marked-runs display',
        \'" x  :  remove run under cursor from list',
        \'" .  :  collapse/open current column',
        \'" ^0 :  move current column to front',
        \'" ------------------------',
        \'" Press ? to remove help',
        \]
    if ! s:runhelp_msg_is_showing
        " temporarily remove 'press ? for help listing' message
        normal! 1G2dd
        call append(line('^'), l:helptext)
        normal! 1G
        let s:runhelp_msg_is_showing = 1
    else
        execute "normal! 1G". len(l:helptext) . "dd"
        call append(line('^'), '" Press ? for help')
        call append(line('^'), 'Vim-MLflow Marked Runs')
        let s:runhelp_msg_is_showing = 0
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


function! RunsPageMLflow()
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

import vim_mlflow_runs  # this import must be after entering python env above
mlflowruns = vim_mlflow_runs.getRunsPageMLflow(vim.eval('g:mlflow_tracking_uri'))
EOF

let mlflowruns = py3eval('mlflowruns')
return mlflowruns
endfunction
