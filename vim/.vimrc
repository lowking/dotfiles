let $BASH_ENV="~/.vim_bash_env"

syntax on
colorscheme jellybeans
set ts=4
set so=5
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set nu
set relativenumber
set ignorecase
set infercase

command Nd :w | !clear; node %
command ND :w | !clear; node %
command Ndp :w | !clear; node % p
command NDP :w | !clear; node % p
command Py :w | !clear; python3 %
command PY :w | !clear; python3 %
