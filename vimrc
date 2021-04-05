
set tabstop=4
set softtabstop=4
set expandtab
set number
set showcmd
set cursorline
syntax on

" Set Insert mode visibility

autocmd InsertEnter * set cul
autocmd InsertLeave * set nocul

" search settings
set ignorecase
set smartcase

" Naviation ----------------------------------------------------------------------------

nnoremap H ^
nnoremap L $

" Key Bindings -------------------------------------------------------------------------
let mapleader = ","

inoremap jk <esc>
xnoremap <leader>p "_dP
noremap <C-p> viw"_dP

set clipboard=unnamedplus


" vim-plug plugins -------------------------------------------------------------------------
" https://github.com/junegunn/vim-plug

call plug#begin('~/.vim/plugged')
  Plug 'preservim/nerdtree'
call plug#end()

" plugin shortcuts -------------------------------------------------------------------------
map <F2> :NERDTreeToggle<CR>
