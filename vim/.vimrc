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

imap ,, <ESC>

command Cg :w | !clear; cargo run
command CG :w | !clear; cargo run
command Ss :w | !clear; . ./%
command SS :w | !clear; . ./%
command Nd :w | !clear; node %
command ND :w | !clear; node %
command Ndp :w | !clear; node % p
command NDP :w | !clear; node % p
command Py :w | !clear; python3 %
command PY :w | !clear; python3 %

" 每次打开光标恢复到上次退出位置
autocmd BufReadPost *
\ if line("'\"") > 0 && line("'\"") <= line("$") |
\   exe "normal g`\"" |
\ endif
