{pkgs, config, lib, ...}:

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
      default = 8000;
    };

    websocketPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming WebSocket connections";
      default = 3012;
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
        };
      };
    };
  };
}