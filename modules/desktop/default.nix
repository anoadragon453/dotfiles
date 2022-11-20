{lib, config, pkgs, ...}:
{
  imports = [
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
    ./kdeconnect.nix
    ./launchers.nix
    ./picom.nix
    ./dunst.nix
    ./terminal.nix
    ./gui.nix
    ./gnome.nix
    ./applications.nix
    ./i3.nix
    ./plymouth.nix
    ./sway.nix
    ./steam.nix
    ./real-time-audio.nix
    ./kanshi.nix
    ./tilewm.nix
    ./wofi-emoji.nix
    ./script.nix
  ];
}
