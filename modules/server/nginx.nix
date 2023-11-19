{ ... }:

{
  config = {
    services.nginx = {
      # Set some reasonable defaults for all virtual hosts.
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
    };

    # Open the typical HTTP ports.
    networking.firewall.allowedTCPPorts = [
      80 443
    ];
  };
}