# This file configures default settings for all shells for all users.
#
# Users will pick which shell they'll actually use via the
# sys.user.users.<username>.shell option
{pkgs, lib, ...}:
with pkgs;
with lib;
with builtins;
{
  sys.software = [
      bash
      zsh # Note: zsh is configured by home-manager
  ];

  environment.variables= {
    "EDITOR" = "nvim";
    "VISUAL" = "nvim";
  }; 

  # This is so you can set zsh or bash as your interactive shell.
  # If you don't set this it will not show your user on the login screen.
  #
  # Note: this is configured for zsh by `programs.zsh.enable` below.
  environment.shells = with pkgs; [ bash ];

  programs.zsh.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    aggressiveResize = true;
  };
}
