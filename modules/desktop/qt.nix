{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiTypes = config.sys.desktop.gui.types;
in {
  config = mkIf (desktopMode && !elem "gnome" desktopGuiTypes) {
    sys.software = with pkgs; [ breeze-qt5 ];
  };
}
