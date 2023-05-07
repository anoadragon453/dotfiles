# This file configures default settings for all shells for all users.
#
# Users will pick which shell they'll actually use via the
# sys.user.users.<username>.shell option
{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
{
  sys.software = [
      bash
      # Note: zsh is installed by the `programs.zsh.enable` option below
  ];

  users.defaultUserShell = pkgs.zsh;

  environment.variables= {
    "EDITOR" = "nvim";
    "VISUAL" = "nvim";
  }; 

  # This is so you can set zsh or bash as your interactive shell.
  # If you don't set this it will not show your user on the login screen.
  #
  # Note: this is configured for zsh by `programs.zsh.enable` below.
  environment.shells = with pkgs; [ bash ];

  # Install and configure zsh
  programs.zsh.enable = true;

  # Enable fish-like greyed-out autosuggestions
  programs.zsh.autosuggestions.enable = true;

  # Enable the Oh-My-Zsh Plugin manager and install a theme and some plugins.
  programs.zsh.ohMyZsh.enable = true;
  programs.zsh.ohMyZsh.plugins = [];
  programs.zsh.ohMyZsh.theme = "spaceship";
  programs.zsh.ohMyZsh.customPkgs = [
    spaceship-prompt
  ];

  # Make history available across terminals, and save this many lines
  # to the file
  programs.zsh.histSize = 10000;    

  sys.user.allUsers.files = {
    zshSettingsKeybindings = {
      path = ".zshrc";
      text = concatStrings ([
        # Fix keybindings.
        # Taken from https://wiki.archlinux.org/title/Zsh
        ''
        # create a zkbd compatible hash;
        # to add other keys to this hash, see: man 5 terminfo
        typeset -g -A key

        key[Home]="''${terminfo[khome]}"
        key[End]="''${terminfo[kend]}"
        key[Insert]="''${terminfo[kich1]}"
        key[Backspace]="''${terminfo[kbs]}"
        key[Delete]="''${terminfo[kdch1]}"
        key[Up]="''${terminfo[kcuu1]}"
        key[Down]="''${terminfo[kcud1]}"
        key[Left]="''${terminfo[kcub1]}"
        key[Right]="''${terminfo[kcuf1]}"
        key[PageUp]="''${terminfo[kpp]}"
        key[PageDown]="''${terminfo[knp]}"
        key[Shift-Tab]="''${terminfo[kcbt]}"

        # setup various keys accordingly
        [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
        [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
        [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
        [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
        [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
        [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-search
        [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-search
        [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
        [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
        [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
        [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
        [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

        # History search with up/down arrows
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search

        # History search with Ctrl-R
        bindkey '^r' history-incremental-search-backward

        # Ctrl-A and Ctrl-E jump to beginning and end of line
        bindkey '^a' beginning-of-line
        bindkey '^e' end-of-line

        [[ -n "''${key[Up]}"   ]] && bindkey -- "''${key[Up]}"   up-line-or-beginning-search
        [[ -n "''${key[Down]}" ]] && bindkey -- "''${key[Down]}" down-line-or-beginning-search

        # Jump by word using Ctrl+arrow keys
        key[Control-Left]="''${terminfo[kLFT5]}"
        key[Control-Right]="''${terminfo[kRIT5]}"

        [[ -n "''${key[Control-Left]}"  ]] && bindkey -- "''${key[Control-Left]}"  backward-word
        [[ -n "''${key[Control-Right]}" ]] && bindkey -- "''${key[Control-Right]}" forward-word

        # Finally, make sure the terminal is in application mode, when zle is
        # active. Only then are the values from $terminfo valid.
        if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
          autoload -Uz add-zle-hook-widget
          function zle_application_mode_start { echoti smkx }
          function zle_application_mode_stop { echoti rmkx }
          add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
          add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
        fi
        ''
      ]);
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    aggressiveResize = true;
  };
}
