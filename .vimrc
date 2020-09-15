set nocompatible  " required for vundle
filetype off      " required for vundle
set rtp+=~/.vim/bundle/Vundle.vim  " include Vundle in runtime path and init

call vundle#begin()  " Keep Plugin commands between vundle#begin/end.
Plugin 'VundleVim/Vundle.vim'            " required for vundle
Plugin 'file:///Users/aganse/Documents/src/python/vim-mlflow'
call vundle#end()            " required

filetype plugin indent on   " required for plugins to work
set encoding=UTF-8

" Brief vundle help:
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
