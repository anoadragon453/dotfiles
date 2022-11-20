{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  desktopGuiType = config.sys.desktop.gui.type;
in {
  config = mkIf (xorg && desktopGuiType == "tiling") {
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
