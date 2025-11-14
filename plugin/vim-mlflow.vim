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
    let g:vim_mlflow_height = get(g:, 'vim_mlflow_height', 10)
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
    let g:vim_mlflow_color_titles = get(g:, 'vim_mlflow_color_titles', 'Statement')
    let g:vim_mlflow_color_divlines = get(g:, 'vim_mlflow_color_divlines', 'vimParenSep')
    let g:vim_mlflow_color_scrollicons = get(g:, 'vim_mlflow_color_scrollicons', 'vimParenSep')
    let g:vim_mlflow_color_selectedexpt = get(g:, 'vim_mlflow_color_selectedexpt', 'String')
    let g:vim_mlflow_color_selectedrun = get(g:, 'vim_mlflow_color_selectedrun', 'Number')
    let g:vim_mlflow_color_help = get(g:, 'vim_mlflow_color_help', 'Comment')
    let g:vim_mlflow_color_markrun = get(g:, 'vim_mlflow_color_markrun', 'Statement')
    let g:vim_mlflow_color_hiddencol = get(g:, 'vim_mlflow_color_hiddencol', 'Comment')
    let g:vim_mlflow_plot_height = get(g:, 'vim_mlflow_plot_height', 25)
    let g:vim_mlflow_plot_width = get(g:, 'vim_mlflow_plot_width', 60)
    let g:vim_mlflow_plot_xaxis = get(g:, 'vim_mlflow_plot_xaxis', 'step')
    let g:vim_mlflow_plot_reuse_buffer = get(g:, 'vim_mlflow_plot_reuse_buffer', 1)
endfunction


function! s:GetPlotBufferName()
    if g:vim_mlflow_plot_reuse_buffer
        return '__MLflowMetricPlot__'
    endif
    if ! exists('s:metric_plot_counter')
        let s:metric_plot_counter = 1
    else
        let s:metric_plot_counter += 1
    endif
    return '__MLflowMetricPlot' . s:metric_plot_counter . '__'
endfunction


function! s:EnsurePlotWindow(bufname)
    if exists('s:plot_winid') && win_gotoid(s:plot_winid)
        if bufexists(a:bufname)
            execute 'buffer ' . fnameescape(a:bufname)
        else
            execute 'enew'
            execute 'file ' . fnameescape(a:bufname)
        endif
        return s:plot_winid
    endif

    let l:main_winnr = bufwinnr(g:vim_mlflow_buffername)
    if l:main_winnr == -1
        let l:main_winnr = winnr()
    endif
    execute l:main_winnr . 'wincmd w'
    execute 'rightb vsplit ' . fnameescape(a:bufname)
    let s:plot_winid = win_getid()
    return s:plot_winid
endfunction


function! s:PopulatePlotBuffer(title, lines)
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nowrap
    setlocal modifiable
    silent normal! gg"_dG
    call setline(1, [a:title] + a:lines)
    setlocal nomodifiable
    call cursor(1, 1)
endfunction


function! s:OpenMetricPlotBuffer(title, lines)
    let l:bufname = s:GetPlotBufferName()
    let l:current_winid = win_getid()
    let l:winid = s:EnsurePlotWindow(l:bufname)
    call win_gotoid(l:winid)
    call s:PopulatePlotBuffer(a:title, a:lines)
    " widen window if needed for plot width + margins
    let l:desired_width = g:vim_mlflow_plot_width + 12
    execute 'vertical resize ' . l:desired_width
    call win_gotoid(l:current_winid)
endfunction


function! RunMLflow()
    let s:debuglines = []
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
    let s:runs_params_are_showing = 1
    let s:runs_metrics_are_showing = 1
    let s:runs_tags_are_showing = 1
    let s:markruns_list = []
    let s:markruns_exptids = []
    let s:numreducedcols = 0
    let s:collapsedcols_list = []
    let s:hiddencols_list = []
    let s:movedcols_list = []
    let s:helptext = []
  
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
    nmap <buffer>  x     :call PlotMetricUnderCursor()<CR>
    nmap <buffer>  o     :call RefreshMLflowBuffer(1)<CR>
    nmap <buffer>  r     :call RefreshMLflowBuffer(0)<CR>
    nmap <buffer>  R     :call OpenRunsWindow()<CR>
    nmap <buffer>  <C-p> :call ToggleMLParamsDisplay()<CR>
    nmap <buffer>  <C-e> :call ToggleMLMetricsDisplay()<CR>
    nmap <buffer>  <C-t> :call ToggleMLTagsDisplay()<CR>
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
    call RefreshRunsBuffer()
    normal! 1G
  
    " Map certain key input to vim-mlflow features within buffer
    nmap <buffer>  ?     :call RunsListHelpMsg()<CR>
    nmap <buffer>  R     :call OpenRunsWindow()<CR>
    nmap <buffer>  .     :call CollapseColumn()<CR>
    nmap <buffer>  x     :call RemoveMarkedRunViaCurpos()<CR>
    " nmap <buffer>  <C-h> :call HideColumn()<CR>
    nmap <buffer>  <C-u> :call UnhideAll()<CR>
    nmap <buffer>  <C-p> :call ToggleRunsParamsDisplay()<CR>
    nmap <buffer>  <C-e> :call ToggleRunsMetricsDisplay()<CR>
    nmap <buffer>  <C-t> :call ToggleRunsTagsDisplay()<CR>

endfunction


" Assign expt+run under cursor in Runs window to remove from runs list
function! RemoveMarkedRunViaCurpos()
    let l:curpos = getpos('.')
    let l:currentLine = getline(l:curpos[1])
  
    " Not clear why couldn't get () operator to work in the regexp in matchstr below;
    " Maybe some issue with vim 'magic'; if () could work then substitute is unnecesary.
    let l:run = substitute(matchstr(l:currentLine, '\m\#[0-9a-fA-F]\{5\} '), '[\# ]', '', 'g')
  
    if l:run != ''
        let s:markruns_list = filter(s:markruns_list, 'v:val[:5] !~ "'.l:run[:5].'"')
    endif
    call RefreshRunsBuffer()
    " Also refresh the main pane so marks disappear there too.
    let l:current_win = win_getid()
    let l:mlflow_winnr = bufwinnr(g:vim_mlflow_buffername)
    if l:mlflow_winnr != -1
        execute l:mlflow_winnr . 'wincmd w'
        call RefreshMLflowBuffer(0)
        call win_gotoid(l:current_win)
    endif
endfunction


" Assign current expt or run under cursor into script variable
function! AssignExptRunFromCurpos(curpos)
    let l:currentLine = getline(a:curpos[1])
  
    " Not clear why couldn't get () operator to work in the regexp in matchstr below;
    " Maybe some issue with vim 'magic'; if () could work then substitute is unnecesary.
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
function! RefreshRunsBuffer()
    let l:curpos = get(a:, 1)
    if ! exists(l:curpos)
        let l:curpos = getpos('.')
    endif
  
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
    call matchadd(g:vim_mlflow_color_titles, 'expt_id.*$')
    if g:vim_mlflow_icon_vdivider != ''
        call matchadd(g:vim_mlflow_color_divlines, repeat(g:vim_mlflow_icon_vdivider, 4).'*')
    endif
    call matchadd(g:vim_mlflow_color_help, '^".*')
    call matchadd(g:vim_mlflow_color_hiddencol, ' : ')
    if g:vim_mlflow_icon_vdivider != ''
        call matchadd(g:vim_mlflow_color_hiddencol, ' '.g:vim_mlflow_icon_vdivider.' ')
    endif
endfunction


function! ColorizeMLflowBuffer()
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
                call add(s:markruns_exptids, s:current_exptid)
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


function! UnhideAll()
    let s:collapsedcols_list = []
    let s:hiddencols_list = []
    let s:movedcols_list = []
    call RefreshRunsBuffer()
endfunction


function! HideColumn()
    let l:curcol = col('.')
    " Convert cursor position into dataframe column # to hide:
    let l:line = getline(5+len(s:debuglines))
    let l:line = strcharpart(l:line, 0, l:curcol)
    let l:colnum = len(split(l:line, ' ')) - 1 + s:numreducedcols
    let l:hiddencols_le_colnum = filter(copy(s:hiddencols_list), {idx, v -> v <= l:colnum})
    let s:numreducedcols = len(l:hiddencols_le_colnum)
    let l:colnum = len(split(l:line, ' ')) - 1 + s:numreducedcols

    if index(s:hiddencols_list, l:colnum) == -1
        call add(s:hiddencols_list, str2nr(l:colnum))
    endif
    call RefreshRunsBuffer()
endfunction


function! CollapseColumn()
    let l:curcol = col('.')
    " Convert cursor position into dataframe column # to collapse:
    let l:line = getline(5+len(s:debuglines))
    let l:line = strcharpart(l:line, 0, l:curcol)
    let l:colnum = len(split(l:line, ' ')) - 1 + s:numreducedcols
    let l:hiddencols_le_colnum = filter(copy(s:hiddencols_list), {idx, v -> v <= l:colnum})
    let s:numreducedcols = len(l:hiddencols_le_colnum)
    let l:colnum = len(split(l:line, ' ')) - 1 + s:numreducedcols

    if index(s:collapsedcols_list, l:colnum) >= 0
        call remove(s:collapsedcols_list, index(s:collapsedcols_list, l:colnum))
    else
        call add(s:collapsedcols_list, str2nr(l:colnum))
    endif
    call RefreshRunsBuffer()
endfunction


function! ToggleMLParamsDisplay()
    if ! s:params_are_showing
        let s:params_are_showing = 1
    else
        let s:params_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleMLMetricsDisplay()
    if ! s:metrics_are_showing
        let s:metrics_are_showing = 1
    else
        let s:metrics_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleMLTagsDisplay()
    if ! s:tags_are_showing
        let s:tags_are_showing = 1
    else
        let s:tags_are_showing = 0
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleRunsParamsDisplay()
    if ! s:runs_params_are_showing
        let s:runs_params_are_showing = 1
    else
        let s:runs_params_are_showing = 0
    endif
    let s:collapsedcols_list = []
    let s:hiddencols_list = []
    let s:movedcols_list = []
    call RefreshRunsBuffer()
endfunction


function! ToggleRunsMetricsDisplay()
    if ! s:runs_metrics_are_showing
        let s:runs_metrics_are_showing = 1
    else
        let s:runs_metrics_are_showing = 0
    endif
    let s:collapsedcols_list = []
    let s:hiddencols_list = []
    let s:movedcols_list = []
    call RefreshRunsBuffer()
endfunction


function! ToggleRunsTagsDisplay()
    if ! s:runs_tags_are_showing
        let s:runs_tags_are_showing = 1
    else
        let s:runs_tags_are_showing = 0
    endif
    let s:collapsedcols_list = []
    let s:hiddencols_list = []
    let s:movedcols_list = []
    call RefreshRunsBuffer()
endfunction


function! ListHelpMsg()
    let s:helptext = [
        \'Vim-MLflow',
        \'" ------------------------',
        \'" ?  :  toggle help listing',
        \'" r  :  requery MLflow display',
        \'" o  :  enter expt or run under cursor',
        \'" <enter> :   "    "    "',
        \'" <space> :  mark run under cursor',
        \'" x  :  plot metric under cursor (if available)',
        \'" R  :  open marked-runs buffer',
        \'" A  :  cycle Active/Deleted/Total view',
        \'" n  :  scroll down list under cursor',
        \'" p  :  scroll up list under cursor',
        \'" N  :  scroll to bottom of list',
        \'" P  :  scroll to top of list',
        \'" ^p :  toggle display of parameters',
        \'" ^e :  toggle display of metrics',
        \'" ^t :  toggle display of tags',
        \'" ------------------------',
        \'" Press ? to remove help',
        \]
    if ! s:help_msg_is_showing
        " temporarily remove 'press ? for help listing' message
        normal! 1G2dd
        call append(line('^'), s:helptext)
        normal! 1G
        let s:help_msg_is_showing = 1
    else
        execute "normal! 1G". len(s:helptext) . "dd"
        call append(line('^'), '" Press ? for help')
        call append(line('^'), 'Vim-MLflow')
        let s:help_msg_is_showing = 0
    endif
    redraw
  
endfunction


function! RunsListHelpMsg()
    let s:helptext = [
        \'Vim-MLflow Marked Runs',
        \'" ------------------------',
        \'" ?  :  toggle help listing',
        \'" R  :  requery marked-runs display',
        \'" x  :  remove run under cursor from list',
        \'" .  :  collapse/open current column',
        \'" ^u :  unhide/undo all column changes',
        \'" ^p :  toggle display of parameters',
        \'" ^e :  toggle display of metrics',
        \'" ^t :  toggle display of tags',
        \'" ------------------------',
        \'" Press ? to remove help',
        \]
        " '" ^h :  hide current column completely',
        " '" ^0 :  move current column to front',
    if ! s:runhelp_msg_is_showing
        " temporarily remove 'press ? for help listing' message
        normal! 1G2dd
        call append(line('^'), s:helptext)
        normal! 1G
        let s:runhelp_msg_is_showing = 1
    else
        execute "normal! 1G". len(s:helptext) . "dd"
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
    # Add the site-packages of the current virtual environment to sys.path
    py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
    sys.path.insert(0, join(project_base_dir, 'lib', py_version_dir, 'site-packages'))

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

try:
    import vim_mlflow  # this import must be after entering python env above
except:
    print("Error: Vim-mlflow requires the mlflow python package to be installed in the environment in which it runs.")
    print("Perhaps you are not in the python environment you think you are, or something was wrong with that install.")
    print("Please see vim-mlflow's readme file for more details.")
    exit
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
    # Add the site-packages of the current virtual environment to sys.path
    py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
    sys.path.insert(0, join(project_base_dir, 'lib', py_version_dir, 'site-packages'))

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

import vim_mlflow_runs  # this import must be after entering python env above
mlflowruns = vim_mlflow_runs.getRunsPageMLflow(vim.eval('g:mlflow_tracking_uri'))
EOF

let mlflowruns = py3eval('mlflowruns')
return mlflowruns
endfunction
" Plot metric history when cursor is on metrics line
function! PlotMetricUnderCursor()
    let l:curline = getline('.')
    let l:match = matchlist(l:curline, '\m^\s\+\(\S\+\):')
    if empty(l:match)
        echo "vim-mlflow: no metric under cursor."
        return
    endif
    let l:metric = l:match[1]
    if ! exists("s:current_runid") || s:current_runid == ""
        echo "vim-mlflow: no run selected."
        return
    endif
    if ! exists("s:metric_histories") || ! has_key(s:metric_histories, s:current_runid)
        echo "vim-mlflow: metric history unavailable; try refreshing."
        return
    endif
    let l:histories = s:metric_histories[s:current_runid]
    if ! has_key(l:histories, l:metric)
        echo "vim-mlflow: metric history not found."
        return
    endif
    let l:history = l:histories[l:metric]
    if len(l:history) <= 1
        echo "vim-mlflow: metric has no series to plot."
        return
    endif
    if ! exists('*json_encode')
        echo "vim-mlflow: json support is required for plotting."
        return
    endif
    let l:history_json = json_encode(l:history)

    " Render the plot via python helper
python3 << EOF
import os, sys, json
from os.path import normpath, join
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
    sys.path.insert(0, join(project_base_dir, 'lib', py_version_dir, 'site-packages'))

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

import vim_mlflow

history = json.loads(vim.eval('l:history_json'))
metric = vim.eval('l:metric')
run_id = vim.eval('s:current_runid')
plot_width = int(vim.eval('g:vim_mlflow_plot_width'))
plot_height = int(vim.eval('g:vim_mlflow_plot_height'))
xaxis_mode = vim.eval('g:vim_mlflow_plot_xaxis')
lines, title = vim_mlflow.render_metric_plot(run_id, metric, history, plot_width, plot_height, xaxis_mode)
vim.vars['vim_mlflow_plot_lines'] = lines
vim.vars['vim_mlflow_plot_title'] = title
EOF
    if ! exists('g:vim_mlflow_plot_lines')
        echo "vim-mlflow: failed to generate plot."
        return
    endif
    let l:plot_lines = get(g:, 'vim_mlflow_plot_lines', [])
    if empty(l:plot_lines)
        echo "vim-mlflow: no plot data available."
        return
    endif
    let l:plot_title = get(g:, 'vim_mlflow_plot_title', '')
    call s:OpenMetricPlotBuffer(l:plot_title, l:plot_lines)
    if exists('g:vim_mlflow_plot_lines')
        unlet g:vim_mlflow_plot_lines
    endif
    if exists('g:vim_mlflow_plot_title')
        unlet g:vim_mlflow_plot_title
    endif
endfunction
