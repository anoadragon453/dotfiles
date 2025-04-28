{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  options.sys.desktop.gui = {
    types = mkOption {
      type = types.listOf (types.enum [ "kde" "gnome" ]);
      default = [ "gnome" ];
      description = ''
      Which desktop environments/window managers/compositors to use.
      `gnome` will set up a GNOME desktop with support for both Xorg and Wayland sessions.
      `kde` will set up a KDE desktop with support for both Xorg and Wayland sessions.
      '';
    };
  };
}