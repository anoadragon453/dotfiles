# matrix-media-repo - Self-hosted photos and videos.
#
{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.matrix-media-repo;
in {
  options.sys.server.matrix-media-repo = {
    enable = lib.mkEnableOption "matrix-media-repo";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host matrix-media-repo on";
    };

    homeserverBaseDomain = lib.mkOption {
      type = lib.types.str;
      description = "The domain where the homserver is hosted";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    # Note: Metrics currently isn't enabled in MMR's config.
    metricsPort = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    adminUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Matrix IDs to give administrative permissions on the service";
    };

    datastores = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of MMR datastores";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "verbose" "debug" "log" "warn" "error" ];
      default = "log";
      description = "The log level to run matrix-media-repo at";
    };
  };

  config = lib.mkIf cfg.enable {

    sys.software = with pkgs; [
      # To support thumbnailing special filetypes.
      ffmpeg
      imagemagick
    ];

    # Put all the config other than secrets here.
    # Then we can layer config files and put the secrets into an sops-encrypted file.
    # Have the decrypted files end up in the MMR config directory.
    # https://docs.t2bot.io/matrix-media-repo/v1.3.5/installation/config/

    # TODO: Setup storagebox.
    # TODO(later): Enable metrics.
    services.matrix-media-repo = {
      configFile = pkgs.writeText {
        name = "matrix-media-repo-config.yaml";
        text = ''
          # General repo configuration
          repo:
            bindAddress: '127.0.0.1'
            port: 8333

            # Where to store the logs, relative to where the repo is started from. Logs will be automatically
            # rotated every day and held for 14 days. To disable the repo logging to files, set this to "-".
            logDirectory: "-"
            trustAnyForwardedAddress: true
            useForwardedHost: true

            # Require authentication for newly uploaded media.
            freezeUnauthenticatedMedia: true

          # The database configuration for the media repository
          database:
            # Currently only "postgres" is supported.
            #postgres: "postgres://matrix_media:7Ofrq3jsas34123aHXUDI333WavIa@localhost/matrix_media?sslmode=disable"
            postgres: "postgres://matrix_media_repo:@/run/postgresql/matrix_media_repo?sslmode=disable"

          # The configuration for the homeservers this media repository is known to control. Servers
          # not listed here will not be able to upload media.
          homeservers:
            - name: ${cfg.domain} # This should match the Host header given to the media repo
              csApi: ${cfg.homeserverBaseDomain} # The base URL to where the homeserver can actually be reached
              backoffAt: 10 # The number of consecutive failures in calling this homeserver before the
                            # media repository will start backing off. This defaults to 10 if not given.
              adminApiKind: "synapse" # The kind of admin API the homeserver supports. If set to "matrix",
                                # the media repo will use the Synapse-defined endpoints under the
                                # unstable client-server API. When this is "synapse", the new /_synapse
                                # endpoints will be used instead. Unknown values are treated as the
                                # default, "matrix".
              signingKeyPath: "/home/synapse/${cfg.domain}.key"

          # These users have full access to the administrative functions of the media repository.
          # See docs/admin.md for information on what these people can do. They must belong to one of the
          # configured homeservers above.
          admins:
            ${lib.concatMapStringsSep "\n" (item: "- ${item}") cfg.adminUsers}

          # Datastores are places where media should be persisted. This isn't dedicated for just uploads:
          # thumbnails and other misc data is also stored in these places. When the media repo is looking
          # to store new media (such as user uploads, thumbnails, etc) it will look for a datastore which
          # is flagged as forUploads. It will try to use the smallest datastore first.
          datastores:
            ${lib.concatMapStringsSep "\n" (datastore: ''
            - id: ${datastore.id}
              type: file
              forKinds: ["thumbnails", "remote_media", "local_media", "archives"]
              forUploads: true
              opts:
                path: ${datastore.filepath}
            '') cfg.datastores}

          # The file upload settings for the media repository
          uploads:
            maxBytes: 104857600 # 100MB default, 0 to disable

            # The minimum number of bytes to let people upload
            minBytes: 100 # 100 bytes by default

          # The number of bytes to claim as the maximum size for uploads for the limits API. If this
          # is not provided then the maxBytes setting will be used instead. This is useful to provide
          # if the media repo's settings and the reverse proxy do not match for maximum request size.
          # This is purely for informational reasons and does not actually limit any functionality.
          # Set this to -1 to indicate that there is no limit. Zero will force the use of maxBytes.
          #reportedMaxBytes: 104857600

          # An optional list of file types that are allowed to be uploaded. If */* or nothing is
          # supplied here, then all file types are allowed. Asterisks (*) are wildcards and can be
          # placed anywhere to match everything (eg: "image/*" matches all images). This will also
          # restrict which file types are downloaded from remote servers.
          allowedTypes:
          - "*/*"

          # Specific users can have their own set of allowed file types. These are applied instead
          # of those listed in the allowedTypes list when a user is found. Much like allowedTypes,
          # asterisks may be used in the content types and may also be used in the user IDs. This
          # allows for entire servers to have different allowed types by setting a rule similar to
          # "@*:example.org". Users will be allowed to upload a file if the type matches any of
          # the policies that match the user ID.
          #exclusions:
          #  "@someone:example.org":
          #     - "application/pdf"
          #     - "application/vnd.ms-excel"
          #  "@*:example.org":
          #     - "*/*"

          # Settings related to downloading files from the media repository
          downloads:
            # The maximum number of bytes to download from other servers
            maxBytes: 504857600 # 100MB default, 0 to disable

            # The number of workers to use when downloading remote media. Raise this number if remote
            # media is downloading slowly or timing out.
            #
            # Maximum memory usage = numWorkers multiplied by the maximum download size
            # Average memory usage is dependent on how many concurrent downloads your users are doing.
            numWorkers: 10

            # How long, in minutes, to cache errors related to downloading remote media. Once this time
            # has passed, the media is able to be re-requested.
            failureCacheMinutes: 5

            # The cache control settings for downloads. This can help speed up downloads for users by
            # keeping popular media in the cache.
            cache:
              enabled: true

              # The maximum size of cache to have. Higher numbers are better.
              maxSizeBytes: 1048576000 # 1GB default

              # The maximum file size to cache. This should normally be the same size as your maximum
              # upload size.
              maxFileSizeBytes: 104857600 # 100MB default

              # The number of minutes to track how many downloads a file gets
              trackedMinutes: 30

              # The number of downloads a file must receive in the window above (trackedMinutes) in
              # order to be cached.
              minDownloads: 5

              # The minimum amount of time an item should remain in the cache. This prevents the cache
              # from cycling out the file if it needs more room during this time.
              minCacheTimeSeconds: 300

              # The minimum amount of time an item should remain outside the cache once it is removed.
              minEvictedTimeSeconds: 60

          # URL Preview settings
          urlPreviews:
            enabled: true # If enabled, the preview_url routes will be accessible
            maxPageSizeBytes: 10485760 # 10MB default, 0 to disable

            # If true, the media repository will try to provide previews for URLs with invalid or unsafe
            # certificates. If false (the default), the media repo will fail requests to said URLs.
            previewUnsafeCertificates: false

            # Note: URL previews are limited to a given number of words, which are then limited to a number
            # of characters, taking off the last word if it needs to. This also applies for the title.

            numWords: 50 # The number of words to include in a preview (maximum)
            maxLength: 200 # The maximum number of characters for a description

            numTitleWords: 30 # The maximum number of words to include in a preview's title
            maxTitleLength: 150 # The maximum number of characters for a title

            # The mime types to preview when OpenGraph previews cannot be rendered. OpenGraph previews are
            # calculated on anything matching "text/*". To have a thumbnail in the preview the URL must be
            # an image and the image's type must be allowed by the thumbnailer.
            filePreviewTypes:
              - "image/*"

            # The number of workers to use when generating url previews. Raise this number if url
            # previews are slow or timing out.
            #
            # Maximum memory usage = numWorkers multiplied by the maximum page size
            # Average memory usage is dependent on how many concurrent urls your users are previewing.
            numWorkers: 10

            # Either allowedNetworks or disallowedNetworks must be provided. If both are provided, they
            # will be merged. URL previews will be disabled if neither is supplied. Each entry must be
            # a CIDR range.
            disallowedNetworks:
              - "127.0.0.1/8"
              - "10.0.0.0/8"
              - "172.16.0.0/12"
              - "192.168.0.0/16"
              - "100.64.0.0/10"
              - "169.254.0.0/16"
              - '::1/128'
              - 'fe80::/64'
              - 'fc00::/7'
            allowedNetworks:
              - "0.0.0.0/0" # "Everything". The blacklist will help limit this.
                            # This is the default value for this field.

          # The thumbnail configuration for the media repository.
          thumbnails:
            # The maximum number of bytes an image can be before the thumbnailer refuses.
            maxSourceBytes: 10485760 # 10MB default, 0 to disable

            # The number of workers to use when generating thumbnails. Raise this number if thumbnails
            # are slow to generate or timing out.
            #
            # Maximum memory usage = numWorkers multiplied by the maximum image source size
            # Average memory usage is dependent on how many thumbnails are being generated by your users
            numWorkers: 100

            # All thumbnails are generated into one of the sizes listed here. The first size is used as
            # the default for when no width or height is requested. The media repository will return
            # either an exact match or the next largest size of thumbnail.
            sizes:
              - width: 32
                height: 32
              - width: 96
                height: 96
              - width: 320
                height: 240
              - width: 640
                height: 480
              - width: 800
                height: 600

            # The content types to thumbnail when requested. Types that are not supported by the media repo
            # will not be thumbnailed (adding application/json here won't work). Clients may still not request
            # thumbnails for these types - this won't make clients automatically thumbnail these file types.
            types:
              - "image/jpeg"
              - "image/jpg"
              - "image/png"
              - "image/gif"
              - "image/heif"
              - "image/webp"
              - "image/svg+xml" # Requires Imagemagick

            # Animated thumbnails can be CPU intensive to generate. To disable the generation of animated
            # thumbnails, set this to false. If disabled, regular thumbnails will be returned.
            allowAnimated: true

            # Default to animated thumbnails, if available
            defaultAnimated: true

            # The maximum file size to thumbnail when a capable animated thumbnail is requested. If the image
            # is larger than this, the thumbnail will be generated as a static image.
            maxAnimateSizeBytes: 10485760 # 10MB default, 0 to disable

            # On a scale of 0 (start of animation) to 1 (end of animation), where should the thumbnailer try
            # and thumbnail animated content? Defaults to 0.5 (middle of animation).
            stillFrame: 0.5

          # Controls for the rate limit functionality
          rateLimit:
            # Set this to false if rate limiting is handled at a higher level or you don't want it enabled.
            enabled: true

            # The number of requests per second before an IP will be rate limited. Must be a whole number.
            requestsPerSecond: 5

            # The number of requests an IP can send at once before the rate limit is actually considered.
            burst: 20

          # Identicons are generated avatars for a given username. Some clients use these to give users a
          # default avatar after signing up. Identicons are not part of the official matrix spec, therefore
          # this feature is completely optional.
          identicons:
            enabled: true

          # The quarantine media settings.
          quarantine:
            # If true, when a thumbnail of quarantined media is requested an image will be returned. If no
            # image is given in the thumbnailPath below then a generated image will be provided. This does
            # not affect regular downloads of files.
            replaceThumbnails: true

            # If provided, the given image will be returned as a thumbnail for media that is quarantined.
            #thumbnailPath: "/path/to/thumbnail.png"

            # If true, administrators of the configured homeservers may quarantine media for their server
            # only. Global administrators can quarantine any media (local or remote) regardless of this
            # flag.
            allowLocalAdmins: true

          # The various timeouts that the media repo will use.
          timeouts:
            # The maximum amount of time the media repo should spend trying to fetch a resource that is
            # being previewed.
            urlPreviewTimeoutSeconds: 10

            # The maximum amount of time the media repo will spend making remote requests to other repos
            # or homeservers. This is primarily used to download media.
            federationTimeoutSeconds: 120

            # The maximum amount of time the media repo will spend talking to your configured homeservers.
            # This is usually used to verify a user's identity.
            clientServerTimeoutSeconds: 30

          # Prometheus metrics configuration
          # For an example Grafana dashboard, import the following JSON:
          # https://t2bot.io/_matrix/media/r0/download/t2l.io/b89e3f042ff2057abcc470d4366a7977
          metrics:
            # If true, the bindAddress and port below will serve GET /metrics for Prometheus to scrape.
            enabled: false

            # The address to listen on. Typically "127.0.0.1" or "0.0.0.0" for all interfaces.
            bindAddress: "127.0.0.1"

            # The port to listen on. Cannot be the same as the general web server port.
            port: ${cfg.metricsPort}
        '';
      };
      
      # Disable Synapse's media repo.
      services.matrix-synapse.settings.enable_media_repo = false;
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
          # Proxy all media requests to matrix-media-repo.
          # TODO: Might need to rewrite the Host header here?
          # https://docs.t2bot.io/matrix-media-repo/v1.3.5/installation/server-names/
          "/_matrix/media" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
          # Media endpoints now also exist on the Client-Server and Server-Server specs as of Matrix v1.11.
          "/_matrix/client/v1/media" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
          "/_matrix/federation/v1/media" = {
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