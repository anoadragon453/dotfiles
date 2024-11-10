{config, lib, ...}:

let
  cfg = config.sys.server.monitoring;
in {
  options.sys.server.monitoring = {
    enable = lib.mkEnableOption "Navidrome Music Streaming Server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the navidrome instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming web and API connections";
    };

    musicLibraryFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The filepath of where music will be stored";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warn" "info" "debug" "trace" ];
      default = "info";
      description = "The log level to run Navidrome at";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;

        settings = {
          # The internal address and port to bind to.
          Address = "127.0.0.1";
          Port = cfg.port;

          # The location of music files.
          MusicFolder = cfg.musicLibraryFilePath;

          # The level to log at.
          LogLevel = cfg.logLevel;

          # Prevent frequent log outs.
          # The largest unit of time that this configuration supports is hours...
          SessionTimeout = "720h";

          # Allow sharing music by public link.
          EnableSharing = true;

          # Enable scraping artist artwork from Spotify.
          Spotify.ID = "3c96bd45ae1547908d43139d0fd97fdb";
          Spotify.Secret = "c6f4edc219224716a5699e7bac488cea";
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
    };
  };
}