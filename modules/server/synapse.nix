# Synapse - Matrix Homeserver
#
{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.matrix-synapse;
in {
  options.sys.server.matrix-synapse = {
    enable = lib.mkEnableOption "matrix-synapse";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host matrix-synapse on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    metricsPort = lib.mkOption {
      type = lib.types.int;
      description = "The port that metrics should be served at";
    };

    mediaStorePath = lib.mkOption {
      type = lib.types.path;
      description = "The filepath at which media files should be stored";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "verbose" "debug" "log" "warn" "error" ];
      default = "log";
      description = "The log level to run matrix-synapse at";
    };
  };

  config = lib.mkIf cfg.enable {
    services.matrix-synapse = {
      enable = true;
      withJemalloc = true;
      extras = ["postgres" "redis" "url-preview"];
      settings = {
        server_name = "amorgan.xyz";
        public_baseurl = "https://matrix.amorgan.xyz";

        # Listen for client and federation traffic on the configured port.
        listeners = [
          {
            bind_addresses = [ "127.0.0.1" ];
            port = cfg.port;
            resources = [
              {
                compress = true;
                names = [
                  "client"
                ];
              }
              {
                compress = false;
                names = [
                  "federation"
                ];
              }
            ];
            tls = false;
            type = "http";
            x_forwarded = true;
          }
        ];

        log.root.level = cfg.logLevel;

        report_stats = true;
        redis.enabled = true;

        enable_metrics = true;

        max_upload_size = "1G";

        # Disable presence for performance reasons.
        presence.enabled = false;

        # TODO: Point to /mnt/media
        media_store_path = "";
      };
    };

    # Configure the reverse proxy to route to this service.
    services.nginx = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        http2 = true;

        # Fetch and configure a TLS cert using the ACME protocol.
        enableACME = true;

        # Redirect all unencrypted traffic to HTTPS.
        forceSSL = true;

        locations = {
          "/metrics/server" = {
            # Proxy to the matrix-synapse server container's metrics port.
            # Note: We include a trailing slash in order to drop the path from
            # the request.
            proxyPass = "http://127.0.0.1:${toString cfg.metricsPortServer}/";
          };

          "/metrics/microservices" = {
            # Proxy to the matrix-synapse microservices container's metrics port.
            # Note: We include a trailing slash in order to drop the path from
            # the request.
            proxyPass = "http://127.0.0.1:${toString cfg.metricsPortMicroservices}/";
          };

          "/" = {
            # Proxy all other traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };

        # Allow uploading media files up to 10 gigabytes in size.
        extraConfig = ''
          client_max_body_size 10G;
        '';
      };
    };
  };
}