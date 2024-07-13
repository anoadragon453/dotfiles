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
    systemd.services.mealie.serviceConfig.ReadWritePaths = lib.mkForce [ cfg.storagePath ];
    services = {
      mealie = {
        enable = true;
        port = cfg.port;
        # user = "mealie";
        settings = {
          ALLOW_SIGNUP = "false";
          TZ = config.sys.timeZone;
          MAX_WORKERS = "1";
          BASE_URL = "https://" + cfg.domain;

          # Override the default data directory.
          DATA_DIR = cfg.storagePath;

          # Configure postgres. I found that mealie would raise errors about
          # database contention with SQLite when bulk importing recipes.
          #
          # We connect to postgres over a unix socket to allow for peer authentication.
          DB_ENGINE = "postgres";
          POSTGRES_URL_OVERRIDE = "postgresql://mealie:@/mealie?host=/run/postgresql";

          LOG_LEVEL = cfg.logLevel;
        };
      };

      # # Create a user for mealie to run as.
      # users.users.mealie = {
      #   isSystemUser = true;
      #   description = "Mealie service user";
      #   group = "mealie";
      #   createHome = false;
      # };

      # # Ensure that the data directory allows the mealie user to read/write to it.
      # systemd.tmpfiles.rules = [
      #   "d ${cfg.storagePath} 0755 mealie mealie -"
      # ];

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