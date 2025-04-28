{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  
  config = mkIf desktopMode {
    # This is *all* nerd-fonts.
    # TODO: Separate out the fonts we actually need.
    fonts.packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerdfonts);
  };
}
