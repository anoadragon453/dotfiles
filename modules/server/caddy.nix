{pkgs, config, lib, ...}:

let
  cfg = config.sys.server;
in {
  options.sys.server.caddy = {
    enable = lib.mkEnableOption "Caddy webserver";
  };

  config = lib.mkIf cfg.caddy.enable {
    services = {
      caddy = {
        enable = true;

        virtualHosts = {}
        // (lib.mkIf cfg.vaultwarden.enable {
          ${cfg.vaultwarden.domain} = {
            extraConfig = ''
              encode gzip

              # The websocket port for desktop clients to get real-time password entry updates.
              reverse_proxy /notifications/hub :${toString cfg.vaultwarden.websocketPort}

              # The Vaultwarden API.
              reverse_proxy :${toString cfg.vaultwarden.port} {
                # Send the true remote IP to for rate-limiting purposes.
                header_up X-Real-IP {remote_host}
              }
            '';
          };
        });
      };
    };

    # Open the typical HTTP ports.
    networking.firewall.allowedTCPPorts = [
      80 443
    ];
  };
}