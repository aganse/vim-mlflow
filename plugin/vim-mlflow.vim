let g:vim_mlflow_version = get(g:, 'vim_mlflow_version', '1.0.0')

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
    let g:vim_mlflow_width = get(g:, 'vim_mlflow_width', 70)
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
        let g:vim_mlflow_icon_hdivider = get(g:, 'vim_mlflow_icon_hdivider', '│')
        let g:vim_mlflow_icon_plotpts = get(g:, 'vim_mlflow_icon_plotpts', '●')
        let g:vim_mlflow_icon_between_plotpts = get(g:, 'vim_mlflow_icon_between_plotpts', '•')
    else
        let g:vim_mlflow_icon_vdivider = get(g:, 'vim_mlflow_icon_vdivider', '-')
        let g:vim_mlflow_icon_scrollstop = get(g:, 'vim_mlflow_icon_scrollstop', '')
        let g:vim_mlflow_icon_scrollup = get(g:, 'vim_mlflow_icon_scrollup', '^')
        let g:vim_mlflow_icon_scrolldown = get(g:, 'vim_mlflow_icon_scrolldown', 'v')
        let g:vim_mlflow_icon_markrun = get(g:, 'vim_mlflow_icon_markrun', '>')
        let g:vim_mlflow_icon_hdivider = get(g:, 'vim_mlflow_icon_hdivider', '|')
        let g:vim_mlflow_icon_plotpts = get(g:, 'vim_mlflow_icon_plotpts', '*')
        let g:vim_mlflow_icon_between_plotpts = get(g:, 'vim_mlflow_icon_between_plotpts', '.')
    endif
    let g:vim_mlflow_color_titles = get(g:, 'vim_mlflow_color_titles', 'Statement')
    let g:vim_mlflow_color_divlines = get(g:, 'vim_mlflow_color_divlines', 'vimParenSep')
    let g:vim_mlflow_color_scrollicons = get(g:, 'vim_mlflow_color_scrollicons', 'vimParenSep')
    let g:vim_mlflow_color_selectedexpt = get(g:, 'vim_mlflow_color_selectedexpt', 'String')
    let g:vim_mlflow_color_selectedrun = get(g:, 'vim_mlflow_color_selectedrun', 'Number')
    let g:vim_mlflow_color_help = get(g:, 'vim_mlflow_color_help', 'Comment')
    let g:vim_mlflow_color_markrun = get(g:, 'vim_mlflow_color_markrun', 'vimParenSep')
    let g:vim_mlflow_color_hiddencol = get(g:, 'vim_mlflow_color_hiddencol', 'Comment')
    let g:vim_mlflow_plot_height = get(g:, 'vim_mlflow_plot_height', 25)
    let g:vim_mlflow_plot_width = get(g:, 'vim_mlflow_plot_width', 70)
    let g:vim_mlflow_plot_xaxis = get(g:, 'vim_mlflow_plot_xaxis', 'step')
    let g:vim_mlflow_plot_reuse_buffer = get(g:, 'vim_mlflow_plot_reuse_buffer', 1)
    let g:vim_mlflow_color_plot_title = get(g:, 'vim_mlflow_color_plot_title', 'Statement')
    let g:vim_mlflow_color_plot_axes = get(g:, 'vim_mlflow_color_plot_axes', 'vimParenSep')
    let g:vim_mlflow_color_plotpts = get(g:, 'vim_mlflow_color_plotpts', 'Constant')
    let g:vim_mlflow_color_between_plotpts = get(g:, 'vim_mlflow_color_between_plotpts', 'Comment')
    let g:vim_mlflow_artifact_expanded = get(g:, 'vim_mlflow_artifact_expanded', {})
    let g:vim_mlflow_artifacts_max_depth = get(g:, 'vim_mlflow_artifacts_max_depth', 3)
    let g:vim_mlflow_section_order = get(g:, 'vim_mlflow_section_order', ['params', 'metrics', 'tags', 'artifacts'])
    if type(g:vim_mlflow_section_order) != type([])
        let g:vim_mlflow_section_order = ['params', 'metrics', 'tags', 'artifacts']
    else
        let g:vim_mlflow_section_order = filter(copy(g:vim_mlflow_section_order), {_, v -> index(['params', 'metrics', 'tags', 'artifacts'], v) != -1})
        if empty(g:vim_mlflow_section_order)
            let g:vim_mlflow_section_order = ['params', 'metrics', 'tags', 'artifacts']
        endif
    endif
endfunction


function! s:GetMainTitle()
    return 'Vim-MLflow v' . get(g:, 'vim_mlflow_version', 'dev')
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

    let l:split_cmd = g:vim_mlflow_vside ==# 'left' ? 'vert botright' : 'vert topleft'
    execute l:split_cmd . ' new'
    execute 'file ' . fnameescape(a:bufname)
    let s:plot_winid = win_getid()
    return s:plot_winid
endfunction


function! s:PopulatePlotBuffer(title, lines)
    setlocal buftype=nofile
    if g:vim_mlflow_plot_reuse_buffer
        setlocal bufhidden=wipe
    else
        setlocal bufhidden=hide
    endif
    setlocal noswapfile
    setlocal nowrap
    setlocal modifiable
    silent normal! gg"_dG
    call setline(1, [a:title] + a:lines)
    setlocal nomodifiable
    call s:ColorizePlotBuffer()
    call cursor(1, 1)
endfunction


function! s:ColorizePlotBuffer()
    call matchadd(g:vim_mlflow_color_plot_title, '\%1l.*')
    call matchadd(g:vim_mlflow_color_selectedexpt, '\%1l\zs#[0-9]\+\ze', 15)
    call matchadd(g:vim_mlflow_color_selectedrun, '\%1l\zs#[0-9a-zA-Z]\{5}\ze', 15)
    if g:vim_mlflow_icon_hdivider != ''
        call matchadd(g:vim_mlflow_color_plot_axes, '\V' . g:vim_mlflow_icon_hdivider)
    endif
    if g:vim_mlflow_icon_vdivider != ''
        call matchadd(g:vim_mlflow_color_plot_axes, '\V' . g:vim_mlflow_icon_vdivider)
    endif
    call matchadd(g:vim_mlflow_color_plot_axes, '\V+')
    if g:vim_mlflow_icon_plotpts != ''
        call matchadd(g:vim_mlflow_color_plotpts, '\V' . g:vim_mlflow_icon_plotpts)
    endif
    if g:vim_mlflow_icon_between_plotpts != ''
        call matchadd(g:vim_mlflow_color_between_plotpts, '\V' . g:vim_mlflow_icon_between_plotpts)
    endif
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
    let s:artifacts_are_showing = 1
    let s:artifact_lineinfo = {}
    let g:vim_mlflow_artifact_expanded = {}
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
    nmap <buffer>  <CR>  :call MLflowSelect()<CR>
    nmap <buffer>  <space>  :call MarkRun()<CR>
    nmap <buffer>  o     :call MLflowSelect()<CR>
    nmap <buffer>  r     :call RefreshMLflowBuffer(0, 1)<CR>
    nmap <buffer>  R     :call OpenRunsWindow()<CR>
    nmap <buffer>  <C-p> :call ToggleMLParamsDisplay()<CR>
    nmap <buffer>  <C-e> :call ToggleMLMetricsDisplay()<CR>
    nmap <buffer>  <C-t> :call ToggleMLTagsDisplay()<CR>
    nmap <buffer>  <C-a> :call ToggleMLArtifactsDisplay()<CR>
    nmap <buffer>  @     :call RotateMLflowSections()<CR>
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
        let g:vim_mlflow_artifact_expanded = {}
    endif
    if l:run != ''
        let s:current_runid = l:run
        let g:vim_mlflow_artifact_expanded = {}
    endif
    call cursor(1, 1)
endfunction


" Requery MLflow content and update buffer
function! RefreshMLflowBuffer(doassign, ...)
    " Optional args: [cursor_position], [reset_artifacts_flag]
    let l:curpos = getpos('.')
    let l:reset_artifacts = 0
    " Allow callers to pass cursor position and/or reset flag via a:000.
    if len(a:000) >= 1
        if type(a:000[0]) == type([])
            let l:curpos = a:000[0]
            if len(a:000) >= 2
                let l:reset_artifacts = a:000[1]
            endif
        else
            let l:reset_artifacts = a:000[0]
        endif
    endif
    if l:reset_artifacts
        let g:vim_mlflow_artifact_expanded = {}
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
    if s:artifacts_are_showing
        let s:artifact_lineinfo = get(g:, 'vim_mlflow_artifact_lineinfo', {})
    else
        let s:artifact_lineinfo = {}
    endif
 
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
    call matchadd(g:vim_mlflow_color_titles, 'Artifacts in run .*:')
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
    let s:actual_expts_length = min([g:vim_mlflow_expts_length, s:num_expts])
    let s:actual_runs_length = min([g:vim_mlflow_runs_length, s:num_runs])
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+s:actual_expts_length &&
     \ s:expts_first_idx < s:num_expts-1
        let s:expts_first_idx = max([0, s:num_expts-s:actual_expts_length])
    elseif l:curpos[1]>l:top_to_expts+s:actual_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+s:actual_expts_length+l:expts_to_runs+s:actual_runs_length &&
     \     s:runs_first_idx < s:num_runs-1
        "let s:runs_first_idx = s:num_runs-1
        let s:runs_first_idx = max([0, s:num_runs-s:actual_runs_length])
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! ScrollListTop()
    let l:top_to_expts = 6
    let l:expts_to_runs = 4
    let l:curpos = getpos('.')
    let s:actual_expts_length = min([g:vim_mlflow_expts_length, s:num_expts])
    let s:actual_runs_length = min([g:vim_mlflow_runs_length, s:num_runs])
    if l:curpos[1]>l:top_to_expts &&
     \ l:curpos[1]<=l:top_to_expts+s:actual_expts_length &&
     \ s:expts_first_idx > 0
        let s:expts_first_idx = 0
    elseif l:curpos[1]>l:top_to_expts+s:actual_expts_length+l:expts_to_runs &&
     \     l:curpos[1]<=l:top_to_expts+s:actual_expts_length+l:expts_to_runs+s:actual_runs_length &&
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
    call ToggleSection('params')
endfunction


function! ToggleMLMetricsDisplay()
    call ToggleSection('metrics')
endfunction


function! ToggleMLTagsDisplay()
    call ToggleSection('tags')
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
    let l:title = s:GetMainTitle()
    let s:helptext = [
        \l:title,
        \'" ------------------------',
        \'" ?  :  toggle help listing',
        \'" r  :  requery MLflow display',
        \'" o  :  open expt/run/plot/artifact under cursor',
        \'" <enter> :   "    "    "',
        \'" <space> :  mark run under cursor',
        \'" R  :  open marked-runs buffer',
        \'" A  :  cycle Active/Deleted/Total view',
        \'" n  :  scroll down list under cursor',
        \'" p  :  scroll up list under cursor',
        \'" N  :  scroll to bottom of list',
        \'" P  :  scroll to top of list',
        \'" ^p :  toggle display of parameters',
        \'" ^e :  toggle display of metrics',
        \'" ^t :  toggle display of tags',
        \'" ^a :  toggle display of artifacts',
        \'" @  :  rotate order of detail sections',
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
        call append(line('^'), l:title)
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
import os, sys, site
from os.path import normpath, join
import vim

def _augment_sys_path():
    def _add_site_dir(path):
        if not os.path.isdir(path):
            return
        before = list(sys.path)
        site.addsitedir(path)
        new_entries = [p for p in sys.path if p not in before]
        for entry in reversed(new_entries):
            idx = sys.path.index(entry)
            sys.path.insert(0, sys.path.pop(idx))

    env_roots = []
    for key in ('VIRTUAL_ENV', 'CONDA_PREFIX', 'PYENV_VIRTUAL_ENV'):
        value = os.environ.get(key)
        if value and value not in env_roots:
            env_roots.append(value)
    for root in env_roots:
        for lib_name in ('lib', 'Lib', 'lib64'):
            lib_dir = os.path.join(root, lib_name)
            if not os.path.isdir(lib_dir):
                continue
            py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
            candidate_dirs = [os.path.join(lib_dir, py_version_dir, 'site-packages')]
            for entry in os.listdir(lib_dir):
                if entry.startswith('python') and entry != py_version_dir:
                    candidate_dirs.append(os.path.join(lib_dir, entry, 'site-packages'))
            for path in candidate_dirs:
                _add_site_dir(path)

_augment_sys_path()

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
if python_root_dir not in sys.path:
    sys.path.insert(0, python_root_dir)

try:
    import vim_mlflow  # this import must be after entering python env above
except ModuleNotFoundError as exc:
    print("Error: Vim-mlflow requires the mlflow python package to be installed in the environment in which it runs.")
    print("Perhaps you are not in the python environment you think you are, or something was wrong with that install.")
    print("Please see vim-mlflow's readme file for more details.")
    print("Underlying import error:", exc)
    raise
mlflowmain = vim_mlflow.getMainPageMLflow(vim.eval('g:mlflow_tracking_uri'))
EOF

let g:vim_mlflow_plugin_loaded = 1
let mlflowmain = py3eval('mlflowmain')
return mlflowmain
endfunction


function! RunsPageMLflow()
python3 << EOF
import os, sys, site
from os.path import normpath, join
import vim

def _augment_sys_path():
    def _add_site_dir(path):
        if not os.path.isdir(path):
            return
        before = list(sys.path)
        site.addsitedir(path)
        new_entries = [p for p in sys.path if p not in before]
        for entry in reversed(new_entries):
            idx = sys.path.index(entry)
            sys.path.insert(0, sys.path.pop(idx))

    env_roots = []
    for key in ('VIRTUAL_ENV', 'CONDA_PREFIX', 'PYENV_VIRTUAL_ENV'):
        value = os.environ.get(key)
        if value and value not in env_roots:
            env_roots.append(value)
    for root in env_roots:
        for lib_name in ('lib', 'Lib', 'lib64'):
            lib_dir = os.path.join(root, lib_name)
            if not os.path.isdir(lib_dir):
                continue
            py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
            candidate_dirs = [os.path.join(lib_dir, py_version_dir, 'site-packages')]
            for entry in os.listdir(lib_dir):
                if entry.startswith('python') and entry != py_version_dir:
                    candidate_dirs.append(os.path.join(lib_dir, entry, 'site-packages'))
            for path in candidate_dirs:
                _add_site_dir(path)

_augment_sys_path()

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
if python_root_dir not in sys.path:
    sys.path.insert(0, python_root_dir)

import vim_mlflow_runs  # this import must be after entering python env above
mlflowruns = vim_mlflow_runs.getRunsPageMLflow(vim.eval('g:mlflow_tracking_uri'))
EOF

let mlflowruns = py3eval('mlflowruns')
return mlflowruns
endfunction
" Plot metric history when cursor is on metrics line
function! HandleMetricPlotUnderCursor()
    let l:line = line('.')
    let l:curline = getline('.')
    let l:metric_lines = get(g:, 'vim_mlflow_metric_lines', [])
    if type(l:metric_lines) != type([])
        let l:metric_lines = []
    endif
    if empty(l:metric_lines)
        return 0
    endif
    if index(l:metric_lines, l:line) == -1
        return 0
    endif
    if l:curline !~# '^\s\{2,}\S\+:'
        return 0
    endif
    let l:match = matchlist(l:curline, '\m^\s\+\(\S\+\):')
    if empty(l:match)
        return 0
    endif
    let l:metric = l:match[1]
    if ! exists("s:current_runid") || s:current_runid == ""
        echo "vim-mlflow: no run selected."
        return 1
    endif
    let l:all_histories = get(g:, 'vim_mlflow_metric_histories', {})
    if type(l:all_histories) != type({})
        let l:all_histories = {}
    endif
    if ! has_key(l:all_histories, s:current_runid)
        echo "vim-mlflow: metric history unavailable; try refreshing."
        return 1
    endif
    let l:histories = l:all_histories[s:current_runid]
    if ! has_key(l:histories, l:metric)
        echo "vim-mlflow: metric history not found."
        return 1
    endif
    let l:history = l:histories[l:metric]
    if len(l:history) <= 1
        echo "vim-mlflow: metric has no series to plot."
        return 1
    endif
    if ! exists('*json_encode')
        echo "vim-mlflow: json support is required for plotting."
        return 1
    endif
    let l:history_json = json_encode(l:history)
    let l:runinfo = get(g:, 'vim_mlflow_current_runinfo', {})
    let l:run_name = get(l:runinfo, 'run_name', '')
    let l:experiment_id = get(l:runinfo, 'experiment_id', '')
    let l:run_name = '' . l:run_name
    let l:experiment_id = '' . l:experiment_id

    " Render the plot via python helper
python3 << EOF
import os, sys, json, site
from os.path import normpath, join
import vim

def _augment_sys_path():
    def _add_site_dir(path):
        if not os.path.isdir(path):
            return
        before = list(sys.path)
        site.addsitedir(path)
        new_entries = [p for p in sys.path if p not in before]
        for entry in reversed(new_entries):
            idx = sys.path.index(entry)
            sys.path.insert(0, sys.path.pop(idx))

    env_roots = []
    for key in ('VIRTUAL_ENV', 'CONDA_PREFIX', 'PYENV_VIRTUAL_ENV'):
        value = os.environ.get(key)
        if value and value not in env_roots:
            env_roots.append(value)
    for root in env_roots:
        for lib_name in ('lib', 'Lib', 'lib64'):
            lib_dir = os.path.join(root, lib_name)
            if not os.path.isdir(lib_dir):
                continue
            py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
            candidate_dirs = [os.path.join(lib_dir, py_version_dir, 'site-packages')]
            for entry in os.listdir(lib_dir):
                if entry.startswith('python') and entry != py_version_dir:
                    candidate_dirs.append(os.path.join(lib_dir, entry, 'site-packages'))
            for path in candidate_dirs:
                _add_site_dir(path)

_augment_sys_path()

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
if python_root_dir not in sys.path:
    sys.path.insert(0, python_root_dir)

import vim_mlflow

history = json.loads(vim.eval('l:history_json'))
metric = vim.eval('l:metric')
run_id = vim.eval('s:current_runid')
plot_width = int(vim.eval('g:vim_mlflow_plot_width'))
plot_height = int(vim.eval('g:vim_mlflow_plot_height'))
xaxis_mode = vim.eval('g:vim_mlflow_plot_xaxis')
experiment_id = vim.eval('l:experiment_id')
run_name = vim.eval('l:run_name')
lines, title = vim_mlflow.render_metric_plot(run_id, metric, history, plot_width, plot_height, xaxis_mode, experiment_id, run_name)
vim.vars['vim_mlflow_plot_lines'] = lines
vim.vars['vim_mlflow_plot_title'] = title
EOF
    if ! exists('g:vim_mlflow_plot_lines')
        echo "vim-mlflow: failed to generate plot."
        return 1
    endif
    let l:plot_lines = get(g:, 'vim_mlflow_plot_lines', [])
    if empty(l:plot_lines)
        echo "vim-mlflow: no plot data available."
        return 1
    endif
    let l:plot_title = get(g:, 'vim_mlflow_plot_title', '')
    call s:OpenMetricPlotBuffer(l:plot_title, l:plot_lines)
    if exists('g:vim_mlflow_plot_lines')
        unlet g:vim_mlflow_plot_lines
    endif
    if exists('g:vim_mlflow_plot_title')
        unlet g:vim_mlflow_plot_title
    endif
    return 1
endfunction


function! MLflowActionUnderCursor()
    let l:line = line('.')
    let l:key = string(l:line)
    for l:entry in get(g:, 'vim_mlflow_section_headers', [])
        if get(l:entry, 'line', -1) == l:line
            let l:section = get(l:entry, 'section', '')
            if !empty(l:section)
                call ToggleSection(l:section)
                return 1
            endif
        endif
    endfor
    let l:info = get(s:artifact_lineinfo, l:key, {})
    if !empty(l:info)
        if l:info.type ==# 'dir'
            call ToggleArtifactDirectory(l:info.path)
        elseif l:info.type ==# 'file'
            if l:info.openable
                call OpenArtifactFile(l:info.path)
            else
                echo "vim-mlflow: artifact not opened (unsupported type)."
            endif
        endif
        return 1
    endif
    return HandleMetricPlotUnderCursor()
endfunction


function! MLflowSelect()
    if MLflowActionUnderCursor()
        return
    endif
    let l:kind = s:GetLineAction()
    if l:kind ==# ''
        return
    endif
    call RefreshMLflowBuffer(1)
endfunction


function! ToggleMLArtifactsDisplay()
    call ToggleSection('artifacts')
endfunction


function! RotateMLflowSections()
    let l:order = filter(copy(g:vim_mlflow_section_order), {_, v -> index(['params', 'metrics', 'tags', 'artifacts'], v) != -1})
    if empty(l:order)
        let l:order = ['params', 'metrics', 'tags', 'artifacts']
    endif
    call add(l:order, remove(l:order, 0))
    let g:vim_mlflow_section_order = l:order
    call RefreshMLflowBuffer(0)
endfunction


function! s:ToggleSectionInternal(section)
    if a:section ==# 'params'
        let s:params_are_showing = 1 - s:params_are_showing
    elseif a:section ==# 'metrics'
        let s:metrics_are_showing = 1 - s:metrics_are_showing
    elseif a:section ==# 'tags'
        let s:tags_are_showing = 1 - s:tags_are_showing
    elseif a:section ==# 'artifacts'
        let s:artifacts_are_showing = 1 - s:artifacts_are_showing
        let g:vim_mlflow_artifact_expanded = {}
        let g:vim_mlflow_artifact_lineinfo = {}
        let s:artifact_lineinfo = {}
    endif
endfunction


function! ToggleSection(section)
    if index(['params', 'metrics', 'tags', 'artifacts'], a:section) == -1
        return
    endif
    call s:ToggleSectionInternal(a:section)
    call RefreshMLflowBuffer(0)
endfunction


function! s:GetLineAction()
    let l:line = getline('.')
    if l:line =~# '^\s*#\d\+:'
        return 'experiment'
    endif
    if l:line =~# '^\s*\S*#\x\{5}:'  " run id is 5 hex chars
        return 'run'
    endif
    return ''
endfunction


function! ToggleArtifactDirectory(path)
    if has_key(g:vim_mlflow_artifact_expanded, a:path)
        call remove(g:vim_mlflow_artifact_expanded, a:path)
    else
        let g:vim_mlflow_artifact_expanded[a:path] = 1
    endif
    call RefreshMLflowBuffer(0)
endfunction


function! OpenArtifactFile(path)
    if a:path == ''
        return
    endif
python3 << EOF
import os, sys, json, tempfile, site
from os.path import normpath, join
import vim

def _augment_sys_path():
    def _add_site_dir(path):
        if not os.path.isdir(path):
            return
        before = list(sys.path)
        site.addsitedir(path)
        new_entries = [p for p in sys.path if p not in before]
        for entry in reversed(new_entries):
            idx = sys.path.index(entry)
            sys.path.insert(0, sys.path.pop(idx))

    env_roots = []
    for key in ('VIRTUAL_ENV', 'CONDA_PREFIX', 'PYENV_VIRTUAL_ENV'):
        value = os.environ.get(key)
        if value and value not in env_roots:
            env_roots.append(value)
    for root in env_roots:
        for lib_name in ('lib', 'Lib', 'lib64'):
            lib_dir = os.path.join(root, lib_name)
            if not os.path.isdir(lib_dir):
                continue
            py_version_dir = 'python{}.{}'.format(sys.version_info.major, sys.version_info.minor)
            candidate_dirs = [os.path.join(lib_dir, py_version_dir, 'site-packages')]
            for entry in os.listdir(lib_dir):
                if entry.startswith('python') and entry != py_version_dir:
                    candidate_dirs.append(os.path.join(lib_dir, entry, 'site-packages'))
            for path in candidate_dirs:
                _add_site_dir(path)

_augment_sys_path()

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
if python_root_dir not in sys.path:
    sys.path.insert(0, python_root_dir)

import vim_mlflow

artifact_path = vim.eval('a:path')
run_id = vim.eval('s:current_runid')
tracking_uri = vim.eval('g:mlflow_tracking_uri')
target_dir = os.path.join(tempfile.gettempdir(), "vim-mlflow")
try:
    local_path = vim_mlflow.download_artifact_file(tracking_uri, run_id, artifact_path, target_dir)
    vim.vars['vim_mlflow_artifact_local'] = local_path
    vim.vars['vim_mlflow_artifact_error'] = ''
except Exception as exc:
    vim.vars['vim_mlflow_artifact_local'] = ''
    vim.vars['vim_mlflow_artifact_error'] = str(exc)
EOF
    if !exists('g:vim_mlflow_artifact_local')
        echo "vim-mlflow: failed to download artifact."
        return
    endif
    let l:local = g:vim_mlflow_artifact_local
    unlet g:vim_mlflow_artifact_local
    if l:local ==# ''
        let l:err = get(g:, 'vim_mlflow_artifact_error', 'artifact download failed')
        echo 'vim-mlflow: ' . l:err
        if exists('g:vim_mlflow_artifact_error')
            unlet g:vim_mlflow_artifact_error
        endif
        return
    endif
    if exists('g:vim_mlflow_artifact_error')
        unlet g:vim_mlflow_artifact_error
    endif
    if filereadable(l:local)
        call s:ShowArtifactBuffer(a:path, l:local)
    else
        echo "vim-mlflow: artifact not readable."
    endif
endfunction


function! s:ShowArtifactBuffer(path, localpath)
    let l:current_win = win_getid()
    let l:bufname = 'artifact://' . a:path
    let l:winnr = bufwinnr(l:bufname)
    if l:winnr == -1
        let l:scratch = s:FindScratchWindow()
        if l:scratch != -1
            call win_gotoid(l:scratch)
            execute 'enew'
        else
            if g:vim_mlflow_vside ==# 'left'
                execute 'vert botright split'
            else
                execute 'vert topleft split'
            endif
        endif
    else
        execute l:winnr . 'wincmd w'
        setlocal modifiable
    endif
    execute 'file ' . fnameescape(l:bufname)
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal modifiable
    let l:content = readfile(a:localpath)
    if empty(l:content)
        let l:content = ['']
    endif
    silent keepjumps %d
    call setline(1, l:content)
    call s:SetBufferFiletype(a:path)
    setlocal nomodifiable
    call cursor(1, 1)
    call win_gotoid(l:current_win)
endfunction


function! s:SetBufferFiletype(path)
    let l:lower = tolower(a:path)
    if l:lower =~ '\v\.json$'
        setfiletype json
    elseif l:lower =~ '\v\.(yaml|yml)$'
        setfiletype yaml
    elseif l:lower =~ '\v\.txt$'
        setfiletype text
    elseif l:lower =~ '\vmlmodel$'
        setfiletype yaml
    else
        setfiletype text
    endif
endfunction


function! s:FindScratchWindow()
    for l:w in range(1, winnr('$'))
        let l:buf = winbufnr(l:w)
        if l:buf <= 0
            continue
        endif
        let l:name = bufname(l:buf)
        if (empty(l:name) || l:name =~? '^artifact://') && getbufvar(l:buf, '&buftype') == ''
            return win_getid(l:w)
        endif
    endfor
    return -1
endfunction
