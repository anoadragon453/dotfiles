# Mealie - recipe management for the modern household.
#
# Mealie is not available as a NixOS module (yet). So deploy it as an OCI
# container instead.
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
    # Based on the official mealie PostgreSQL docker-compose file:
    # https://nightly.mealie.io/documentation/getting-started/installation/postgres/
    virtualisation.oci-containers.containers."mealie" = {
      # Start this container on boot.
      autoStart = true;

      image = "ghcr.io/mealie-recipes/mealie:v1.0.0-RC2";

      # Expose port 9000 in the container to the configured port on the host.
      # TODO: We cannot set ports while the network mode is 'host' (see below).
      # ports = [
      #   "${toString cfg.port}:9000"
      # ];

      extraOptions = [
        # The mealie container's `/app/run.sh` script does not respond to
        # SIGTERM, causing attempts to stop the systemd service to hang.
        #
        # We use an init script provided by the container backend as a
        # workaround, which will run `/app/run.sh` but also properly
        # respond to SIGTERM.
        # https://github.com/mealie-recipes/mealie/issues/2723
        "--init"
        # TODO: We currently have to set the network mode to 'host' to work around
        # https://github.com/NixOS/nixpkgs/issues/272480
        "--network=host"
      ];

      volumes = [
        "${cfg.storagePath}:/app/data/"
        "/run/postgresql:/run/postgresql"
      ];

      # Configure mealie settings.
      # Available options: https://nightly.mealie.io/documentation/getting-started/installation/backend-config/
      environment = {
        ALLOW_SIGNUP = "false";
        # Mealie appears to run as root (uid 0) regardless, see
        # https://github.com/mealie-recipes/mealie/issues/2845
        PUID = "1000";
        PGID = "1000";
        TZ = config.sys.timeZone;
        MAX_WORKERS = "1";
        BASE_URL = "https://" + cfg.domain;

        # Configure postgres. I found that mealie would raise errors about
        # database contention with SQLite when bulk importing recipes.
        DB_ENGINE = "postgres";
        POSTGRES_USER = "mealie";
        POSTGRES_SERVER = "localhost";
        POSTGRES_DB = "mealie";

        LOG_LEVEL = cfg.logLevel;
      };
    };

    services = {
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
            # Proxy all other traffic straight through.
            # TODO: Currently have to hardcode to 9000 due to using network mode in the container.
            # proxyPass = "http://127.0.0.1:${toString cfg.port}";
            proxyPass = "http://127.0.0.1:9000";
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

        # Since mealie is running inside a container that doesn't have a "mealie" user,
        # and we can't do password authentication for postgres users in NixOS... let's just
        # allow anyone connecting from localhost to access the mealie database over TCP,
        # regardless of the password they're using.
        authentication = ''
          host    mealie    mealie    127.0.0.1/32    trust
          host    mealie    mealie    ::1/128         trust
        '';
        settings = {
          # Allow incoming TCP connections from localhost.
          listen_addresses = "localhost";
        };
      };
    };
  };
}