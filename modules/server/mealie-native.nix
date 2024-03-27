# Mealie - recipe management for the modern household.
#
{config, lib, ...}:

let
  cfg = config.sys.server.mealie;
in {
  options.sys.server.mealie = {
    enable = lib.mkEnableOption "Mealie";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the mealie instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    storagePath = lib.mkOption {
      type = lib.types.path;
      description = "The filepath at which persistent mealie files should be stored";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "ERROR" "WARNING" "INFO" "DEBUG" "CRITICAL" ];
      default = "INFO";
      description = "The log level to run mealie at";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      mealie = {
        enable = true;
        port = cfg.port;
        settings = {
          ALLOW_SIGNUP = "false";
          TZ = config.sys.timeZone;
          MAX_WORKERS = "1";
          BASE_URL = "https://" + cfg.domain;

          # Override the default data directory.
          # TODO: Might need to lib.mkForce here?
          DATA_DIR = cfg.storagePath;

          # Configure postgres. I found that mealie would raise errors about
          # database contention with SQLite when bulk importing recipes.
          DB_ENGINE = "postgres";
          POSTGRES_USER = "mealie";
          POSTGRES_SERVER = "localhost";
          POSTGRES_DB = "mealie";

          LOG_LEVEL = cfg.logLevel;
        };
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

          locations."/" = {
            # Proxy all traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };
      };

      # Initialise a postgres database for mealie to use.
      postgresql = {
        enable = true;
        ensureDatabases = [ "mealie" ];
        ensureUsers = [
          {
            name = "mealie";
            ensureDBOwnership = true;
          }
        ];
      };
    };
  };
}