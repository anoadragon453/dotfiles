{config, lib, ...}:

let
  cfg = config.sys.server.tor;
in {
  options.sys.server.tor = {
    enable = lib.mkEnableOption "Tor relay";

    torPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming Tor connections";
    };

    directoryPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming directory requests";
    };

    nickname = lib.mkOption {
      type = lib.types.str;
      description = "The (public) name of the tor node";
    };

    accountingMax = lib.mkOption {
      type = lib.types.str;

      # Just under the default 20TB network traffic Hetzner offers.
      default = "19728 GB";

      description = "The maximum number of bytes to transfer per month";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      # Act as a relay (a middle node) in the Tor network.
      tor = {
        relay = {
          enable = true;
          role = "relay";
        };
        
        # Configure the relay node.
        settings = {
          Nickname = cfg.nickname;

          ORPort = cfg.torPort;
          DirPort = cfg.directoryPort;

          # TODO: MetricsPort, MetricsPortPolicy and scrape through Prometheus to Grafana

          AccountingMax = cfg.accountingMax;

          # Reset the counter on the first every month at midnight.
          AccountStart = "month 1 00:00";

          # Publish my mail address so that others can contact me about this
          # node if needed.
          # This has been useful in the past for out-of-date notifications.
          ContactInfo = "andrew / a//t amorgan . xyz>";
        };
      };
    };

    # Open the public ports in the firewall.
    networking.firewall.allowedTCPPorts = [ cfg.torPort cfg.directoryPort ];
  };
}