{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  cfg = config.sys.desktop.kdeconnect;
in {
  options.sys.desktop.kdeconnect = {
    enable = mkEnableOption "Enable KDEConnect functionality for connecting to mobile devices";

    # TODO: This could be automatically chosen if this flake ever supported choosing between GNOME and KDE.
    implementation = mkOption {
      type = types.enum [ "kdeconnect" "gsconnect" ];
      default = "kdeconnect";
      description = "The implementation backend to use. Use KDEConnect with KDE and GSConnect with GNOME";
    };
  };

  config = mkIf (desktopMode && cfg.enable) {
    programs.kdeconnect.enable = (mkIf (cfg.implementation == "kdeconnect") true);

    sys.software = (mkIf (cfg.implementation == "gsconnect") [
      pkgs.gnomeExtensions.gsconnect
    ]);

    # Although KDEConnect and GSConnect use the same port ranges, we only need to do this
    # for gsconnect, as programs.kdeconnect.enable already does this for us.
    networking.firewall.allowedTCPPortRanges = (mkIf (cfg.implementation == "gsconnect") [
      { from = 1716; to = 1764; }
    ]);
    networking.firewall.allowedUDPPortRanges = (mkIf (cfg.implementation == "gsconnect") [
      { from = 1716; to = 1764; }
    ]);

  };
}