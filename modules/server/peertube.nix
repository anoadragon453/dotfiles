{config, lib, ...}:

let
  cfg = config.sys.server.peertube;
in {
  options.sys.server.peertube = {
    enable = lib.mkEnableOption "PeerTube Video Streaming Server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the peertube instance on";
    };

    httpPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming API connections (from javascript/tools)";
    };

    webPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming web connections (from a browser)";
    };

    peertubeSecretFilePath = lib.mkOption {
      type = lib.types.str;
      description = "A file containing the secret for peertube";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warn" "info" "debug" ];
      default = "info";
      description = "The log level to run peertube at";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      # Redis pops up a warning if this isn't enabled, as otherwise errors can
      # be caused when the system is low on memory.
      redis.vmOverCommit = true;

      peertube = {
        enable = true;

        # Install redis (if not already) and create a peertube-specific instance.
        redis.createLocally = true;
        redis.enableUnixSocket = true;

        # Install postgres (if not already) and create a peertube-specific database.
        # By default, the port is 5432.
        database.createLocally = true;

        # Specify the http port to listen on.
        listenHttp = cfg.httpPort;

        # The port that PeerTube will be publicly accessible on.
        listenWeb = 443;

        # Tell PeerTube that we're going to be running it on HTTPS via the
        # reverse proxy.
        enableWebHttps = true;

        # The domain that the service will be running on.
        localDomain = cfg.domain;

        # Automatically set up an nginx virtual host.
        # TODO: Acme enabled?
        configureNginx = true;

        # A secret that PeerTube needs (potentially for cryptographic operations?).
        secrets.secretsFile = config.sops.secrets."${cfg.peertubeSecretFilePath}".path;

        # Allow the PeerTube systemd service to access the persistent storage directory
        # on the storagebox.
        dataDirs = [ "/mnt/storagebox/media/peertube" ];

        # View all configuration options: https://github.com/Chocobozzz/PeerTube/blob/develop/config/default.yaml
        settings = {
          signup = {
            enabled = false;
          };

          instance = {
            name = "Peertube";
            short_description = "A personal peertube instance";
            description = ''
              Welcome to my peertube instance! Currently, this is only for hosting my own videos.

              Feel free to browse any that are public.
            '';
            administrator = ''
              This instance is managed by Andrew Morgan.
              You can contact me on matrix [here](https://matrix.to/#/@andrewm:amorgan.xyz).
            '';
            business_model = "Self-funded";
            languages = [ "en" ];
            is_nsfw = false;
          };

          # Allow users to update a new version of a video without changing metadata.
          video_file.update.enabled = true;

          # Bump the rate limit to allow mass uploads via the CLI.
          rates_limit.api = {
            max = 500;
          };

          # Only allow incoming connections from local services (i.e. the reverse proxy).
          listen.hostname = "127.0.0.1";

          # Set the log level.
          log.level = cfg.logLevel;

          # Specify the storage paths.
          storage = {
            avatars = "/mnt/storagebox/media/peertube/avatars";
            streaming_playlists = "/mnt/storagebox/media/peertube/streaming-playlists";
            previews = "/mnt/storagebox/media/peertube/previews";
            thumbnails = "/mnt/storagebox/media/peertube/thumbnails";
            storyboards = "/mnt/storagebox/media/peertube/storyboards";
            torrents = "/mnt/storagebox/media/peertube/torrents";
            captions = "/mnt/storagebox/media/peertube/captions";
            plugins = "/mnt/storagebox/media/peertube/plugins";
            # Note: "videos" has been renamed to "web_videos" in the upcoming PeerTube v6.0.0.
            # After we update to that version, "videos" can be removed.
            videos = "/mnt/storagebox/media/peertube/videos";
            web_videos = "/mnt/storagebox/media/peertube/videos";
          };
        };
      };

      # Enable ACME on the nginx virtual host.
      nginx.virtualHosts.${cfg.domain} = {
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}