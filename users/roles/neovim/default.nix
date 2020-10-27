{pkgs, config, lib, ...}:
{
  home.sessionVariables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
  };

  home.packages = with pkgs; [
    vimwiki-markdown
  ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      nerdtree
      nerdtree-git-plugin
      nord-vim
      vim-devicons
#      vim-nerdtree-syntax-highlight
      vimwiki
    ];

    extraConfig = ''
      " Basic editor config
      set clipboard+=unnamedplus
      set mouse=a
      set encoding=utf-8
      set number relativenumber
      set noswapfile
      set nobackup
      set nowritebackup
      set tabstop=2
      set shiftwidth=2
      set softtabstop=2
      set expandtab
      set ai "Auto indent
      set si "Smart indent
      set pyxversion=3 "Avoid using python 2 when possible, its eol

      " No annoying sound on errors
      set noerrorbells
      set novisualbell
      set t_vb=
      set tm=500

      "Colour theme
      colorscheme nord
      let g:lightline = { 'colorscheme': 'nord', }

      "Nerd tree config
      map <C-n> :NERDTreeToggle<CR>
      let NERDTreeShowHidden=1

      "COC settings
      map <a-cr> :CocAction<CR>
      "Vim wiki settings
      let g:vimwiki_list = [{'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md', 'path_html': '~/vimwiki/site_html', 'custom_wiki2html': 'vimwiki_markdown'}]

      " Disable Arrow keys in Normal mode
      map <up> <nop>
      map <down> <nop>
      map <left> <nop>
      map <right> <nop>

      " Disable Arrow keys in Insert mode
      imap <up> <nop>
      imap <down> <nop>
      imap <left> <nop>
      imap <right> <nop>
  '';
  };
}
  
