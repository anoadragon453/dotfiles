{lib, ...}:
{
  config = {
    # A work-around for https://github.com/NixOS/nixpkgs/issues/180175
    # where reloading NixOS gets delayed and failing due to nm-online
    # timing out.
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

    networking = {
      nameservers = [
        # Cloudflare DNS
        "1.1.1.1"

        # Google DNS
        "8.8.8.8"
      ];

      # Don't listen to suggestions from the network gateway.
      networkmanager.dns = "none";
    };
  };
}
