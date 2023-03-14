{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  desktopGuiTypes = config.sys.desktop.gui.types;
in {
  config = mkIf (xorg && elem "tiling" desktopGuiTypes) {
    sys.software = with pkgs; [ picom ];

    services.picom = {
      enable = true;
      fade = true;
      fadeDelta = 5;
      shadow = true;
      backend = "glx";
    };
  };
}
