{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  
  config = mkIf desktopMode {
    # Override the bizarre default of "terminate:ctrl_alt_bksp" which prevents
    # Ctrl+Backspace from working in GNOME apps.
    services.xserver.xkb.options = "";
  };
}
