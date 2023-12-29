{ lib, osConfig, pkgs, ... }:
{
  gtk = lib.mkIf (builtins.length osConfig.sys.hardware.graphics.desktopProtocols != 0) {
    enable = true;

    # Note that changing any theme settings in GNOME Tweaks will
    # delete the symlinks that home-manager has created and replace
    # them with new files. These will need to be cleared again manually,
    # otherwise home-manager will complain about them when reloading.
    cursorTheme = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
    };

    iconTheme = {
      # Yes, it requires a lowercase d...
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
  };
}