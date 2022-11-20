{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiType = config.sys.desktop.gui.type;
in {
  config = mkIf (desktopMode && desktopGuiType != "gnome") {
    sys.software = with pkgs; [ breeze-qt5 ];
  };
}
