{ lib, osConfig, pkgs, ... }:
{
  home.shellAliases = {
    # Shorthands for common git commands.
    ga = "git add";
    gb = "git branch";
    gc = "git commit";
    gch = "git checkout";
    gd = "git diff";
    gl = "git log";
    gca = "git commit --amend";
    gcm = "git commit -m";
    gcp = "git cherry-pick";
    gf = "git fetch";
    gp = "git push";
    gpf = "git push --force-with-lease";
    gpl = "git pull";
    gr = "git rebase -i";
    gs = "git stash";
    gsp = "git stash pop";

    # Alias vim to nvim
    vim = "nvim";
    
    # Replace common shell utilities with modern replacements.
    cat = "bat";
    n = "yazi";
    zj = "zellij";
  };

  # Enable the 'z' command (with fzf integration) to jump between directories.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Install and configure zsh
  programs.zsh.enable = true;

  # Enable fish-like greyed-out autosuggestions
  programs.zsh.autosuggestion.enable = true;

  # Enable the Oh-My-Zsh Plugin manager and install a theme and some plugins.
  programs.zsh.oh-my-zsh.enable = true;
  # programs.zsh.oh-my-zsh.plugins = ["spaceship-prompt"];
  # programs.zsh.oh-my-zsh.theme = "spaceship";

  programs.zsh.plugins = [
    {
      name = "spaceship-prompt";
      file = "spaceship.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "spaceship-prompt";
        repo = "spaceship-prompt";
        rev = "v4.16.0";
        sha256 = "sha256-WjeUF8yD3il9DAava/SYv7ID6iM9AbR1ppazJnypgnk=";
      };
    }
  ];

  # Fix keybindings.
  # Taken from https://wiki.archlinux.org/title/Zsh
  programs.zsh.initExtra = ''
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
  # TODO: This is here while I lack a better place to put it. For yubikey auth.
  #
  # Required to set the SSH_AUTH_SOCK env var correctly. Although this should
  # be done by `programs.gnupg.agent.enableSSHSupport` below, something else is
  # setting SSH_AUTH_SOCK and interfering. We just override it here instead.
  + (if osConfig.sys.security.yubikey.legacySSHSupport then ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket);
  '' else "");
}