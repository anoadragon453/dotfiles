{config, lib, ...}:

let
  cfg = config.sys.server.vaultwarden;
in {
  options.sys.server.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden Password Manager Server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the vaultwarden instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for the VaultWarden API";
    };

    websocketPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming WebSocket connections";
    };

    environmentFileSecret = lib.mkOption {
      type = lib.types.str;
      description = "A sops secret pointing to an .env file containing extra configuration for Vaultwarden";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warn" "info" "debug" "trace" "off" ];
      default = "info";
      description = "The log level to run Vaultwarden at";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      vaultwarden = {
        enable = true;

        # View all configuration options: https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
        config = {
          # The domain that the webserver will be running behind.
          DOMAIN = "https://" + cfg.domain;

          # Disable signups.
          SIGNUPS_ALLOWED = false;

          # The port to listen for incoming API connections on.
          ROCKET_PORT = cfg.port;

          # The port to listen for incoming Websocket connections on.
          WEBSOCKET_PORT = cfg.websocketPort;

          # The log level to log at.
          LOG_LEVEL = cfg.logLevel;
        };

        environmentFile = config.sops.secrets."${cfg.environmentFileSecret}".path;
      };

      # Configure the reverse proxy to route to this service.
      nginx = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          http2 = true;

          # Fetch and configure a TLS cert using the ACME protocol.
          enableACME = true;

          # Redirect all unencrypted traffic to HTTPS.
          forceSSL = true;

          locations."/notifications/hub" = {
            # Proxy traffic on this path to the websocket port.
            proxyPass = "http://127.0.0.1:${toString cfg.websocketPort}";
          };

          locations."/" = {
            # Proxy all other traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };
      };
    };
  };
}