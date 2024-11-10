# Immich - Self-hosted photos and videos.
#
{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.immich;
in {
  options.sys.server.immich = {
    enable = lib.mkEnableOption "Immich";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host Immich on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    metricsPortServer = lib.mkOption {
      type = lib.types.int;
      description = "The port that the server container should listen on for prometheus metrics";
    };

    metricsPortMicroservices = lib.mkOption {
      type = lib.types.int;
      description = "The port that the microservices container should listen on for prometheus metrics";
    };

    storagePath = lib.mkOption {
      type = lib.types.path;
      description = "The filepath at which persistent Immich files should be stored";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "verbose" "debug" "log" "warn" "error" ];
      default = "log";
      description = "The log level to run Immich at";
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;
      port = cfg.port;
      host = "127.0.0.1";
      mediaLocation = "/mnt/storagebox/media/immich";
      settings = {
        server.externalDomain = "https://${cfg.domain}";
      };
      environment = {
        IMMICH_METRICS = "true";
        IMMICH_API_METRICS_PORT = toString cfg.metricsPortServer;
        IMMICH_MICROSERVICES_METRICS_PORT = toString cfg.metricsPortMicroservices;

        IMMICH_LOG_LEVEL = cfg.logLevel;
      };
    };

    systemd.services.immich-server.serviceConfig = {
      PrivateMounts = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      WorkingDirectory = lib.mkForce cfg.storagePath;
      RuntimeDirectory = lib.mkForce null;
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
            # Proxy to the immich server container's metrics port.
            # Note: We include a trailing slash in order to drop the path from
            # the request.
            proxyPass = "http://127.0.0.1:${toString cfg.metricsPortServer}/";
          };

          "/metrics/microservices" = {
            # Proxy to the immich microservices container's metrics port.
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