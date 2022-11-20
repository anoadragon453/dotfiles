{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
  cfg = config.sys.vpn;
in {
  options.sys = {
    vpn.service = mkOption {
      type = types.enum [ "mullvad" "none" ];
      default = "mullvad";
      description = "Configure a given VPN service on this system";
    };
  };

  config = {
    # System daemon services.
    services.mullvad-vpn.enable = (mkIf (cfg.service == "mullvad") true);

    # User-facing apps/cli.
    sys.software = (mkIf (cfg.service == "mullvad") [
      mullvad-vpn
    ]);
  };
}
