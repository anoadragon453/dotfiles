{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  options.sys.desktop.gui = {
    type = mkOption {
      type = types.enum [ "gnome" "tiling" ];
      default = "gnome";
      description = "The desktop environment/window manager/compositor to use. `gnome` will set up a GNOME desktop with support for both Xorg and Wayland sessions. `tiling` will configure i3 (on Xorg) and sway (on Wayland).";
    };
  };
}