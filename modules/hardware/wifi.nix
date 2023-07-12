{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  cfg = config.sys.networking;
in {
  options.sys.networking = {
    wifi = mkEnableOption "Enable wifi";
    rtw88Support = mkEnableOption "Enable support for rtw88 wifi cards";
  };

  config = {
    networking.networkmanager.enable = true;
    networking.wireless.enable = cfg.wifi;
    networking.wireless.allowAuxiliaryImperativeNetworks = cfg.wifi;
    # networking.wireless.networks = wifiNetworks; #TODO: add networks to wifi via activation script.

    sys = mkIf cfg.rtw88Support {
      software = with pkgs; [
        rtw88-firmware
      ];
    };
  };
}
