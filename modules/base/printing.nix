{pkgs, config, lib, ...}:
with lib;
let
  cfg = config.sys;
in {
  options.sys = {
    enablePrintingSupport = mkEnableOption "Enable printing support on this system";
  };

  config = {
    services.printing.enable = cfg.enablePrintingSupport;
  };
}
