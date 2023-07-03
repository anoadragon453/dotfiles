{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
  cfg = config.sys.vpn;
in {
  options.sys = {
    vpn.services = mkOption {
      type = types.listOf (types.enum [ "tailscale" "mullvad" ]);
      default = [];
      description = "Configure one or more given VPN services on this system";
    };
  };

  config = {
    # System daemon services.
    services.mullvad-vpn.enable = (elem "mullvad" cfg.services);
    services.tailscale.enable = (elem "tailscale" cfg.services);

    # User-facing apps/cli.
    sys.software = [
      (mkIf (elem "mullvad" cfg.services) mullvad-vpn)
    ];
  };
}
