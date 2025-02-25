# Synapse - Matrix Homeserver
#
{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.matrix-synapse;
in {
  options.sys.server.matrix-synapse = {
    enable = lib.mkEnableOption "matrix-homeserver";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the homeserver on";
    };

    delegationDomain = lib.mkOption {
      type = lib.types.str;
      description = "The domain from which .well-known files are hosted on for Matrix federation delegation";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    metricsPort = lib.mkOption {
      type = lib.types.int;
      description = "The port that metrics should be served on";
    };

    manholePort = lib.mkOption {
      type = lib.types.int;
      description = "The port that Synapse's manhole should be served on";
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

  config = lib.mkIf cfg.enable (
    let 
      # Maximum size for uploaded media files.
      maxUploadSize = "10G";
  in {
    # The Matrix homeserver implementation.
    # TODO: Previous Synapse version: 1.105.1
    # https://element-hq.github.io/synapse/latest/upgrade.html
    services.matrix-synapse = {
      enable = true;
      withJemalloc = true;
      extras = ["postgres" "redis" "url-preview"];
      configureRedisLocally = true;
      settings = {
        server_name = "amorgan.xyz";
        public_baseurl = "https://${cfg.domain}";

        listeners = [
          # Client and federation traffic.
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

          # Metrics.
          {
            bind_addresses = [ "127.0.0.1" ];
            port = cfg.metricsPort;
            type = "metrics";
          }

          # Manhole access. This port MUST NOT be made publicly accessible.
          # https://element-hq.github.io/synapse/latest/manhole
          {
            bind_addresses = [ "127.0.0.1" ];
            port = cfg.manholePort;
            type = "manhole";
          }
        ];

        # TODO: Database configuration. Doesn't need a secret, just need to copy data.
        #
        # TODO: Note, retention was enabled, hence large DB size. How to bring it down?
        #
        # database:
        #   allow_unsafe_locale: true
        #   name: psycopg2
        #   args:
        #       user: synapse_user
        #       password: h89y89YNDAHSiudlhdil31hkjlasdhhiuahdhj1hgkj32hiua
        #       database: synapse
        #       host: localhost
        #       cp_min: 5
        #       cp_max: 10

        # TODO: Replication port. workers. caching. etc.

        # TODO: Caching

        # TODO: TURN server.

        # TODO: Anti-spam invites module.

        # TODO: Registration shared secret.
        enable_registration = false;
        allow_guest_access = false;

        # Set the logging level.
        log.root.level = cfg.logLevel;

        enable_metrics = true;
        report_stats = true;

        max_upload_size = maxUploadSize;

        # Disable presence for performance reasons.
        presence.enabled = false;
      };
    };

    # Configure the reverse proxy to route to this service.
    services.nginx = 
      let
        # A function to generate a .well-known response with given JSON body.
        #
        # Taken from https://nixos.org/manual/nixos/unstable/#module-services-matrix-synapse
        mkWellKnown = data: ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON data}';
        '';

        clientWellKnown = {
          "m.homeserver" = {
            base_url = cfg.domain;
          };
        };
        serverWellKnown = {
          "m.server" = "${cfg.domain}:443";
        };
    in {
      enable = true;

      # Host .well-known Matrix client and server config in order to delegate from the
      # user-friendly domain to the one where the homeserver is *actually* hosted.
      virtualHosts.${cfg.delegationDomain} = {
        http2 = true;

        # Fetch and configure a TLS cert using the ACME protocol.
        enableACME = true;

        # Redirect all unencrypted traffic to HTTPS.
        forceSSL = true;

        locations = {
          "= /.well-known/matrix/server".extraConfig = mkWellKnown serverWellKnown;
          "= /.well-known/matrix/client".extraConfig = mkWellKnown clientWellKnown;
        };
      };

      virtualHosts.${cfg.domain} = {
        http2 = true;

        # Fetch and configure a TLS cert using the ACME protocol.
        enableACME = true;

        # Redirect all unencrypted traffic to HTTPS.
        forceSSL = true;

        locations = {
          "/_matrix" = {
            # Proxy all other traffic to Synapse.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
          
          "/metrics" = {
            # Proxy prometheus metrics requests to the homeserver's metrics port.
            proxyPass = "http://127.0.0.1:${toString cfg.metricsPort}";
          };
        };

        # Allow uploading media files up to 10 gigabytes in size.
        extraConfig = ''
          client_max_body_size ${maxUploadSize};
        '';
      };
    };
  });
}