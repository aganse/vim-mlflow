let g:vim_mlflow_skip_python_check = 1
let v:errors = []

source plugin/vim-mlflow.vim

highlight default Statement cterm=NONE gui=NONE
highlight default String cterm=NONE gui=NONE
highlight default Number cterm=NONE gui=NONE
highlight default Comment cterm=NONE gui=NONE
highlight default Constant cterm=NONE gui=NONE
highlight default vimParenSep cterm=NONE gui=NONE

function! s:GetPluginSid()
    for l:line in split(execute('scriptnames'), "\n")
        if l:line =~# 'plugin/vim-mlflow.vim$'
            return '<SNR>' . matchstr(l:line, '^\s*\zs\d\+\ze:') . '_'
        endif
    endfor
    return ''
endfunction


function! s:CallPluginFunc(name, args)
    return call(function(s:plugin_sid . a:name), a:args)
endfunction


function! s:ResetLayout(vside)
    silent! only
    if bufexists(g:vim_mlflow_buffername)
        execute 'bwipeout! ' . fnameescape(g:vim_mlflow_buffername)
    endif
    enew
    setlocal noswapfile
    let g:vim_mlflow_vside = a:vside
    execute 'file ' . g:vim_mlflow_buffername
endfunction


function! s:GetWindowBufferNames()
    let l:names = []
    for l:w in range(1, winnr('$'))
        call add(l:names, bufname(winbufnr(l:w)))
    endfor
    return l:names
endfunction


function! s:GetWindowHeightForBuffer(bufname)
    for l:w in range(1, winnr('$'))
        if bufname(winbufnr(l:w)) ==# a:bufname
            return winheight(l:w)
        endif
    endfor
    return -1
endfunction


function! s:GetWrapForBuffer(bufname)
    for l:w in range(1, winnr('$'))
        if bufname(winbufnr(l:w)) ==# a:bufname
            return getwinvar(l:w, '&wrap')
        endif
    endfor
    return -1
endfunction


let s:plugin_sid = s:GetPluginSid()
call assert_notequal('', s:plugin_sid)

call SetDefaults()
call assert_equal('http://localhost:5000', g:mlflow_tracking_uri)
call assert_equal(8, g:vim_mlflow_expts_length)
call assert_equal('-', g:vim_mlflow_icon_vdivider)
call assert_equal(66, g:vim_mlflow_plotpane_pct)
call assert_equal('selected_expt', g:vim_mlflow_runs_cache_mode)

let g:vim_mlflow_icon_useunicode = 1
unlet g:vim_mlflow_icon_vdivider
call SetDefaults()
call assert_equal(nr2char(9472), g:vim_mlflow_icon_vdivider)

let g:vim_mlflow_section_order = 'invalid'
call SetDefaults()
call assert_equal(['params', 'metrics', 'tags', 'artifacts'], g:vim_mlflow_section_order)

call SetDefaults()
let s:file1 = tempname()
let s:file2 = tempname()
call writefile(['one'], s:file1)
call writefile(['two'], s:file2)
call s:ResetLayout('left')
call s:CallPluginFunc('ShowArtifactBuffer', ['first.txt', s:file1])
call assert_equal([g:vim_mlflow_buffername, 'artifact://unknown/first.txt'], s:GetWindowBufferNames())
call assert_equal(0, s:GetWrapForBuffer('artifact://unknown/first.txt'))
call s:CallPluginFunc('ShowArtifactBuffer', ['second.txt', s:file2])
call assert_equal([g:vim_mlflow_buffername, 'artifact://unknown/second.txt'], s:GetWindowBufferNames())
call delete(s:file1)
call delete(s:file2)

call SetDefaults()
let s:artifact_file = tempname()
let s:artifact_file_2 = tempname()
call writefile(['artifact'], s:artifact_file)
call writefile(['artifact-two'], s:artifact_file_2)
call s:ResetLayout('left')
call s:CallPluginFunc('ShowArtifactBuffer', ['artifact.txt', s:artifact_file])
call s:CallPluginFunc('OpenMetricPlotBuffer', ['Plot title', ['line one']])
call assert_equal([g:vim_mlflow_buffername, '__MLflowMetricPlot__', 'artifact://unknown/artifact.txt'], s:GetWindowBufferNames())
call assert_true(s:GetWindowHeightForBuffer('__MLflowMetricPlot__') > s:GetWindowHeightForBuffer('artifact://unknown/artifact.txt'))
call s:CallPluginFunc('ShowArtifactBuffer', ['artifact-two.txt', s:artifact_file_2])
call assert_equal([g:vim_mlflow_buffername, '__MLflowMetricPlot__', 'artifact://unknown/artifact-two.txt'], s:GetWindowBufferNames())
call assert_true(s:GetWindowHeightForBuffer('__MLflowMetricPlot__') > s:GetWindowHeightForBuffer('artifact://unknown/artifact-two.txt'))
call delete(s:artifact_file)
call delete(s:artifact_file_2)

call SetDefaults()
let s:artifact_file = tempname()
let s:artifact_file_2 = tempname()
call writefile(['artifact'], s:artifact_file)
call writefile(['artifact-two'], s:artifact_file_2)
call s:ResetLayout('right')
call s:CallPluginFunc('OpenMetricPlotBuffer', ['Plot title', ['line one']])
call s:CallPluginFunc('ShowArtifactBuffer', ['artifact.txt', s:artifact_file])
call assert_equal(['__MLflowMetricPlot__', 'artifact://unknown/artifact.txt', g:vim_mlflow_buffername], s:GetWindowBufferNames())
call assert_true(s:GetWindowHeightForBuffer('__MLflowMetricPlot__') > s:GetWindowHeightForBuffer('artifact://unknown/artifact.txt'))
call s:CallPluginFunc('ShowArtifactBuffer', ['artifact-two.txt', s:artifact_file_2])
call assert_equal(['__MLflowMetricPlot__', 'artifact://unknown/artifact-two.txt', g:vim_mlflow_buffername], s:GetWindowBufferNames())
call assert_true(s:GetWindowHeightForBuffer('__MLflowMetricPlot__') > s:GetWindowHeightForBuffer('artifact://unknown/artifact-two.txt'))
call delete(s:artifact_file)
call delete(s:artifact_file_2)

call SetDefaults()
let g:vim_mlflow_plotpane_pct = 50
call SetDefaults()
let s:artifact_file = tempname()
call writefile(['artifact'], s:artifact_file)
call s:ResetLayout('left')
call s:CallPluginFunc('OpenMetricPlotBuffer', ['Plot title', ['line one']])
call s:CallPluginFunc('ShowArtifactBuffer', ['artifact.txt', s:artifact_file])
call assert_true(abs(s:GetWindowHeightForBuffer('__MLflowMetricPlot__') - s:GetWindowHeightForBuffer('artifact://unknown/artifact.txt')) <= 1)
call delete(s:artifact_file)

if len(v:errors) > 0
    echoerr join(v:errors, "\n")
    " echom string(v:errors)
    cquit 1
endif
