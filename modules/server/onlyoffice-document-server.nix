# OnlyOffice DocumentServer
#
# This is only the document server backend, and is intended to be used with some
# OnlyOffice Editors frontend. Either hosted as its own service, hosted as a
# NextCloud plugin, or just installed locally on the desktop.
#
{config, lib, ...}:

let
  cfg = config.sys.server.onlyoffice-document-server;
in {
  options.sys.server.onlyoffice-document-server = {
    enable = lib.mkEnableOption "OnlyOffice DocumentServer";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the onlyoffice documentserver instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    jwtSecretFilePath = lib.mkOption {
      type = lib.types.str;
      description = "A file containing the JWT secret for external authentication to the DocumentServer";
    };
  };

  config = lib.mkIf cfg.enable {
    # HACK: onlyoffice-documentserver contains a full, running nginx instance with
    # everything configured to route requests to the onlyoffice-documentserver.
    # However, a problem arises if you want to expose this service over TLS to the
    # internet, and you already have another webserver running (in my case, caddy),
    # which is set up to handle TLS and solve ACME challenges on port 80. Thus, nginx
    # can't be set up to automatically solve ACME challenges, as there's a port conflict.
    #
    # The solution I've chosen to solve this is to disable nginx (the lines below), and
    # instead convert the nginx config to caddy config in caddy.nix.
    #
    # TODO: Upstream allowing users to choose nginx or caddy in nixpkgs.
    services.nginx.enable = false;
    users.users.nginx.isNormalUser = true;
    users.users.nginx.group = "nogroup";

    services = {
      onlyoffice = {
        # This will also enable and set up PostgreSQL and RabbitMQ for us.
        enable = true;

        # The domain that the webserver will be running behind.
        hostname = cfg.domain;

        # The port to listen for incoming connections on. This is for internal
        # connections only, and a separate reverse proxy running on the machine
        # should target this, and expose the service externally itself.
        port = cfg.port;

        # The path to a file containing a secret that clients must provide in an
        # Authorization HTTP header in order to connect to the DocumentServer.
        jwtSecretFile = config.sops.secrets."${cfg.jwtSecretFilePath}".path;
      };
    };
  };
}