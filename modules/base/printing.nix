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

    # Driver for EPSON XP-970 printer.
    services.printing.drivers = with pkgs; [ epson-escpr2 ];
  };
}
