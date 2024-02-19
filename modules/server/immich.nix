# Immich - Self-hosted photos and videos.
#
# Immich is not available as a NixOS module (yet). So deploy it as an OCI
# container instead. See https://github.com/NixOS/nixpkgs/pull/244803 for
# progress on packaging it natively for NixOS.
#
# This file adapted from Diogo Correia's dotfiles:
# https://github.com/diogotcorreia/dotfiles/blob/7676201683a3785ef17eff9f4ad3295375c670bd/hosts/hera/immich.nix
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

  config = lib.mkIf cfg.enable
    (let
      images = {
        serverAndMicroservices = {
          imageName = "ghcr.io/immich-app/immich-server";
          imageDigest =
            "sha256:c7b80752d48464dea1c4495ff810365a0809d89c2ac219547d3c1aed81c6411f"; # v1.94.1
          sha256 = "sha256-Xd/dBmT9fqT1zVpAr0dfMSnBJ6LI2X5YI31cIrqPULk=";
        };
        machineLearning = {
          imageName = "ghcr.io/immich-app/immich-machine-learning";
          imageDigest =
            "sha256:a3c612c548d5f547a31d001d97f661d7acd4a0ae354de76a70e45162d2b81014"; # v1.94.1
          sha256 = "sha256-ePrVgaJ/QTz15TuJgp/C6UkrKKWD/yGeIn6Fs3EbXzE=";
        };
      };
      dbUsername = user;

      redisName = "immich";

      user = "immich";
      group = user;
      uid = 15015;
      gid = 15015;

      immichWebUrl = "http://immich_web:3000";
      immichServerUrl = "http://immich_server:3001";
      immichMachineLearningUrl = "http://immich_machine_learning:3003";

      # Full environment variable docs: https://immich.app/docs/install/environment-variables
      environment = {
        DB_URL = "socket://${dbUsername}:@/run/postgresql?db=${dbUsername}";

        REDIS_SOCKET = config.services.redis.servers.${redisName}.unixSocket;

        UPLOAD_LOCATION = cfg.storagePath;

        IMMICH_WEB_URL = immichWebUrl;
        IMMICH_SERVER_URL = immichServerUrl;
        IMMICH_MACHINE_LEARNING_URL = immichMachineLearningUrl;

        LOG_LEVEL = cfg.logLevel;
      };

      # A function to wrap a docker image as a locally built container.
      # TODO: I think this is only useful for ensuring image digests are followed?
      wrapImage = { name, imageName, imageDigest, sha256, entrypoint }:
        pkgs.dockerTools.buildImage ({
          name = name;
          tag = "release";
          fromImage = pkgs.dockerTools.pullImage {
            imageName = imageName;
            imageDigest = imageDigest;
            sha256 = sha256;
          };
          created = "now";
          config = if builtins.length entrypoint == 0 then
            null
          else {
            Cmd = entrypoint;
            WorkingDir = "/usr/src/app";
          };
        });

      # A function to build a container volume mount string that maps to the
      # same place in the container as on the host.
      mkMount = dir: "${dir}:${dir}";
    in {
      # Create a system user that Immich can run under, allowing for peer
      # authentication to the postgres database.
      users.users.${user} = {
        inherit group uid;
        isSystemUser = true;
      };
      users.groups.${group} = { inherit gid; };

      # Create a postgres database for Immich, and install the pgvecto-rs plugin
      # which we build separately as a custom package (see pkgs/default.nix).
      services.postgresql = {
        ensureUsers = [{
          name = dbUsername;
          ensureDBOwnership = true;
          # Make the "immich" user a superuser such that it can create
          # postgres extensions.
          ensureClauses.superuser = true;
        }];
        ensureDatabases = [ dbUsername ];

        extraPlugins = [
          pkgs.pgvecto-rs
        ];
        settings = { shared_preload_libraries = "vectors.so"; };
      };

      # Create a redis server instance specifically for Immich.
      services.redis.servers.${redisName} = {
        inherit user;
        enable = true;
      };

      # Ensure that the directory where photos will be stored exists.
      # TODO: This appear to fail with the following error:
      # fchownat() of /mnt/storagebox/media/immich failed: Permission denied
      #
      # systemd.tmpfiles.rules = [ "d ${cfg.storagePath} 0750 ${user} ${group}" ];

      # Start the OCI containers necessary to run an Immich server.
      # The containers are connected via a bridge network called "immich-bridge".
      virtualisation.oci-containers.containers = {
        immich_server = {
          imageFile = wrapImage {
            inherit (images.serverAndMicroservices) imageName imageDigest sha256;
            name = "immich_server";
            entrypoint = [ "/bin/sh" "start-server.sh" ];
          };
          image = "immich_server:release";
          extraOptions =
            [ "--network=immich-bridge" "--user=${toString uid}:${toString gid}" ];

          volumes = [
            "${cfg.storagePath}:/usr/src/app/upload"
            (mkMount "/run/postgresql")
            (mkMount "/run/redis-${redisName}")
          ];

          environment = environment // {
            PUID = toString uid;
            PGID = toString gid;
          };

          ports = [ "${toString cfg.port}:3001" ];

          autoStart = true;
        };

        immich_microservices = {
          imageFile = wrapImage {
            inherit (images.serverAndMicroservices) imageName imageDigest sha256;
            name = "immich_microservices";
            entrypoint = [ "/bin/sh" "start-microservices.sh" ];
          };
          image = "immich_microservices:release";
          extraOptions =
            [ "--network=immich-bridge" "--user=${toString uid}:${toString gid}" ];

          volumes = [
            "${cfg.storagePath}:/usr/src/app/upload"
            (mkMount "/run/postgresql")
            (mkMount "/run/redis-${redisName}")
          ];

          environment = environment // {
            PUID = toString uid;
            PGID = toString gid;
            REVERSE_GEOCODING_DUMP_DIRECTORY = "/tmp/reverse-geocoding-dump";
          };

          autoStart = true;
        };

        immich_machine_learning = {
          imageFile = pkgs.dockerTools.pullImage images.machineLearning;
          image = "ghcr.io/immich-app/immich-machine-learning";
          extraOptions = [ "--network=immich-bridge" ];

          environment = environment;

          volumes = [ "immich-model-cache:/cache" ];

          autoStart = true;
        };
      };

      systemd.services = {
        init-immich-network = {
          description = "Create the network bridge for immich.";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          # We hardcode the docker command here (instead of using ${pkgs.docker}/bin/docker)
          # in order to allow for compatibility with podman's docker wrapper.
          script = ''
            # Put a true at the end to prevent getting non-zero return code, which would
            # otherwise cause the service to fail.
            check=$(/run/current-system/sw/bin/docker network ls | grep "immich-bridge" || true)

            if [ -z "$check" ];
              then /run/current-system/sw/bin/docker network create immich-bridge
              else echo "immich-bridge docker network already exists"
            fi
          '';
        };

        # TODO: Regardless of creating the extensions manually, Immich still
        # complains that it can't create the extensions. So... I've just given
        # it superuser for now above.
        #
        # enable-immich-postgresql-extensions = {
        #   description = "Activate required Postgres extensions for Immich";
        #   after = [ "network.target" ];
        #   wantedBy = [ "multi-user.target" ];
        #   serviceConfig = {
        #     # Run this as the postgres user so that we have super-user powers.
        #     User = "postgres";
        #     Group = "postgres";

        #     Type = "oneshot";
        #   };
        #   script = ''
        #     # Create extensions if they don't already exist.
        #     # psql will exit with an error code if the extension already exists, so append "|| true"
        #     # to have the operation always succeed.
        #     ${config.services.postgresql.package}/bin/psql ${dbUsername} -c "CREATE EXTENSION cube" || true
        #     ${config.services.postgresql.package}/bin/psql ${dbUsername} -c "CREATE EXTENSION earthdistance" || true
        #   '';
        # };
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

          locations."/" = {
            # Proxy all traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };

          # Allow uploading media files up to 10 gigabytes in size.
          extraConfig = ''
            client_max_body_size 10G;
          '';
        };
      };
    });
}