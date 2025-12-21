let g:vim_mlflow_skip_python_check = 1
let v:errors = []

source plugin/vim-mlflow.vim

call SetDefaults()
call assert_equal('http://localhost:5000', g:mlflow_tracking_uri)
call assert_equal(8, g:vim_mlflow_expts_length)
call assert_equal('-', g:vim_mlflow_icon_vdivider)

let g:vim_mlflow_icon_useunicode = 1
unlet g:vim_mlflow_icon_vdivider
call SetDefaults()
call assert_equal(nr2char(9472), g:vim_mlflow_icon_vdivider)

let g:vim_mlflow_section_order = 'invalid'
call SetDefaults()
call assert_equal(['params', 'metrics', 'tags', 'artifacts'], g:vim_mlflow_section_order)

if len(v:errors) > 0
    echom string(v:errors)
    cquit 1
endif
