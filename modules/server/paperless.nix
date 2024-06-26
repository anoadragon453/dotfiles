{config, lib, ...}:

let
  cfg = config.sys.server.paperless;
in {
  options.sys.server.paperless = {
    enable = lib.mkEnableOption "Paperless-ngx Document Management System";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the paperless instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming HTTP connections";
    };

    superuserPasswordFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The path of the file containing the superuser's password";
    };

    appDataFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The filepath where application data will be stored";
    };

    documentsFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The filepath where documents will be stored";
    };
  };

  config = lib.mkIf cfg.enable
  {
    services = {
      paperless = {
        enable = cfg.enable;

        port = cfg.port;
        passwordFile = config.sops.secrets."${cfg.superuserPasswordFilePath}".path;
        mediaDir = cfg.documentsFilePath;
        dataDir = cfg.appDataFilePath;

        # View all configuration options: https://docs.paperless-ngx.com/configuration/
        settings = {
          PAPERLESS_DBHOST = "/run/postgresql";

          PAPERLESS_URL = "https://${cfg.domain}";
        };
      };

      # Initialise a postgres database for paperless to use.
      postgresql = {
        enable = true;
        ensureDatabases = [ "paperless" ];
        ensureUsers = [
          {
            name = "paperless";
            ensureDBOwnership = true;
          }
        ];
      };

      nginx = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          http2 = true;

          # Fetch and configure a TLS cert using the ACME protocol.
          enableACME = true;

          # Redirect all unencrypted traffic to HTTPS.
          forceSSL = true;

          locations."/" = {
            # Proxy all traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };
      };
    };
  };
}