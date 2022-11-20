{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
    options.sys = {
      enableFlatpakSupport = mkEnableOption "Enable support for installing flatpaks on this system";
    };

    config = {
      services.flatpak.enable = cfg.enableFlatpakSupport;

      # Required for Flatpak support.
      xdg.portal.enable = true;
    };
}