{config, lib, ...}:

let
  cfg = config.sys.server.navidrome;
in {
  options.sys.server.navidrome = {
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

        # View all configuration options: https://www.navidrome.org/docs/usage/configuration-options/
        settings = {
          # The internal address and port to bind to.
          Address = "127.0.0.1";
          Port = cfg.port;

          # The location of music files.
          MusicFolder = cfg.musicLibraryFilePath;

          # The level to log at.
          LogLevel = cfg.logLevel;

          # Allow sharing music by public link.
          EnableSharing = true;
        };
      };
    };
  };
}