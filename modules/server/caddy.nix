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

        extraConfig = ''
          # CORS configuration.
          (cors) {
            header_down Access-Control-Allow-Origin *
            header_down Access-Control-Request-Method *
            header_down Access-Control-Request-Headers *
          }
        '';

        virtualHosts = {
          # Navidrome
          ${cfg.navidrome.domain} = lib.mkIf cfg.navidrome.enable {
            extraConfig = ''
              encode gzip

              reverse_proxy :${toString cfg.navidrome.port}
            '';
          };

          # OnlyOffice Document Server
          ${cfg.onlyoffice-document-server.domain} = lib.mkIf cfg.onlyoffice-document-server.enable {

            # This config was created by taking the generated nginx config produced by the onlyoffice-documentserver
            # package, and using ChatGPT to convert it to Caddyfile v2 config.
            extraConfig = ''
              encode gzip

              route {
                reverse_proxy /* http://localhost:${toString cfg.onlyoffice-document-server.port}
                reverse_proxy /${pkgs.onlyoffice-documentserver.version}/* http://localhost:${toString cfg.onlyoffice-document-server.port}
                
                rewrite / /welcome/

                rewrite /OfficeWeb/apps/* /${pkgs.onlyoffice-documentserver.version}/web-apps{path}
                rewrite /web-apps/apps/* /${pkgs.onlyoffice-documentserver.version}{path}

                handle_path /d+./d+./d+./doc/* {
                  reverse_proxy localhost:${toString cfg.onlyoffice-document-server.port}{path}
                }

                handle_path /d+./d+./d+./dictionaries/* {
                  root * ${pkgs.onlyoffice-documentserver}/var/www/onlyoffice/documentserver/dictionaries
                }

                handle_path /d+./d+./d+./web-apps/apps/api/documents/api.js {
                  root * ${pkgs.onlyoffice-documentserver}/var/www/onlyoffice/documentserver/web-apps/apps/api/documents
                }

                handle_path /d+./d+./d+./{web-apps,sdkjs,sdkjs-plugins,fonts}/* {
                  root * ${pkgs.onlyoffice-documentserver}/var/www/onlyoffice/documentserver/{1}
                }

                handle_path /welcome/* {
                  root * ${pkgs.onlyoffice-documentserver}/var/www/onlyoffice/documentserver-example
                  try_files {path} docker.html
                }

                handle_path /d+./d+./d+./{info,internal}/* {
                  @allowed {
                    remote_ip 127.0.0.1
                  }
                  reverse_proxy @allowed localhost:${toString cfg.onlyoffice-document-server.port}{path}
                  respond "Forbidden" 403
                }

                header {
                  Host {http.request.host}
                  X-Forwarded-Host {http.request.host}
                  X-Forwarded-Proto {http.request.scheme}
                  X-Forwarded-For {http.request.remote}
                  Upgrade {http.request.header.Upgrade}
                  Connection {http.request.header.Connection}
                }
              }
            '';
          };

          # Tandoor
          ${cfg.tandoor-recipes.domain} = lib.mkIf cfg.tandoor-recipes.enable {
            extraConfig = ''
              encode gzip

              reverse_proxy :${toString cfg.tandoor-recipes.port}
            '';
          };

          # Vaultwarden
          ${cfg.vaultwarden.domain} = lib.mkIf cfg.vaultwarden.enable {
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
        };
      };
    };

    # Open the typical HTTP ports.
    networking.firewall.allowedTCPPorts = [
      80 443
    ];
  };
}