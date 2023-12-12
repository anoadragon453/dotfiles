{config, lib, ...}:

let
  cfg = config.sys.server.tandoor-recipes;
in {
  options.sys.server.tandoor-recipes = {
    enable = lib.mkEnableOption "Tandoor Recipe Service";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the tandoor instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming web connections";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warning" "info" "debug" "critical" ];
      default = "info";
      description = "The log level to run Tandoor at";
    };

    secretKeySecret = lib.mkOption {
      type = lib.types.str;
      description = "A sops secret pointing to an .env file containing extra configuration for tandoor";
    };
  };

  # TODO: Switch to grocy?
  config = lib.mkIf cfg.enable {
    services = {
      tandoor-recipes = {
        enable = cfg.enable;

        # The interface tandoor should listen on.
        address = "127.0.0.1";
        port = cfg.port;

        # View all configuration options: https://raw.githubusercontent.com/vabene1111/recipes/master/.env.template
        # Note: TIMEZONE is set automatically by the tandoor-recipes nixpkgs package.
        # Recipes are stored at /var/lib/tandoor-recipes.
        extraConfig = {
          # Whether to allow open sign ups.
          ENABLE_SIGNUP = 0;

          # Whether to expose prometheus metrics.
          ENABLE_METRICS = 0;

          # The level to log at.
          GUNICORN_LOG_LEVEL = cfg.logLevel;

          # Allow exporting recipes as a PDF.
          # TODO: Tries to export to /.local... which doesn't work!
          ENABLE_PDF_EXPORT = 0;

          # Database config matching the postgresql config below.
          DB_ENGINE = "django.db.backends.postgresql";
          POSTGRES_HOST = "/run/postgresql";
          POSTGRES_USER = "tandoor_recipes";
          POSTGRES_DB = "tandoor_recipes";
        };
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

      # Initialise a postgres database for tandoor-recipes to use.
      postgresql = {
        enable = true;
        ensureDatabases = [ "tandoor_recipes" ];
        ensureUsers = [
          {
            # The tandoor-recipes package runs the process as the user 'tandoor_recipes'.
            name = "tandoor_recipes";
            ensurePermissions."DATABASE tandoor_recipes" = "ALL PRIVILEGES";
          }
        ];
      };
    };

    # Ensure tandoor starts *after* postgres.
    systemd.services = {
      tandoor-recipes = {
        after = [ "postgresql.service" ];

        serviceConfig = {
          # Set the SECRET_KEY option from a file.
          # This is a secret key that tandoor uses to derive other secrets from.
          EnvironmentFile = config.sops.secrets."${cfg.secretKeySecret}".path;
        };
      };
    };
  };
}