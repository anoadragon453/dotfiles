{config, lib, ...}:

let
  cfg = config.sys.server.bookstack;
in {
  options.sys.server.bookstack = {
    enable = lib.mkEnableOption "Bookstack server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the bookstack instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming web and API connections";
    };

    dataDirFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The filepath of where persistent files will be stored";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warn" "info" "debug" "trace" ];
      default = "info";
      description = "The log level to run bookstack at";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      bookstack = {
        enable = true;

        database = {
          name = "bookstack";
          user = "bookstack";

        };

        config = {

        };

        appURL = "https://${cfg.domain}";
      };
    };
  };


  # Initialise a mariadb database for bookstack to use.

}