{pkgs, config, lib, ...}:
with lib;
with builtins;
let

  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;

in {
  config = mkIf desktopMode {
    boot.plymouth = {
      enable = true;
      theme = "colorful_sliced";
      themePackages = [
        # Install plymouth themes from adi1090x.
        (pkgs.adi1090x-plymouth-themes.overrideAttrs (final: prev: {
          # Ensure this package only installs the theme(s) we plan to use.
          selected_themes = [ "colorful_sliced" ];
        }))
      ];
    };

  };

}
