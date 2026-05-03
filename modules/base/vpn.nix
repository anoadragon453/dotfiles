{pkgs, pkgsUnstable, config, lib, ...}:
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

    services.tailscale = {
      enable = (elem "tailscale" cfg.services);

      # Use the unstable version as work prefers this stays as
      # up-to-date as possible.
      package = pkgsUnstable.tailscale;
    };

    # User-facing apps/cli.
    sys.software = optional (elem "mullvad" cfg.services) mullvad-vpn;
  };
}
