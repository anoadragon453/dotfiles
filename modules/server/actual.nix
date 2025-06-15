# ActualBudget - Self-hosted budget-tracking website.
#
{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.actual;
in {
  options.sys.server.actual = {
    enable = lib.mkEnableOption "ActualBudget";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host ActualBudget on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on";
    };

    storagePath = lib.mkOption {
      type = lib.types.path;
      description = "The filepath at which persistent ActualBudget files should be stored";
    };
  };

  config = lib.mkIf cfg.enable {
    services.actual = {
      enable = true;

      # TODO: Our pikapods server is on v25.6.1, but nixpkgs only has v25.5.0
      # packaged. Unfortunately, updating to v25.6.0 requires changes:
      # https://github.com/NixOS/nixpkgs/issues/414050
      #
      # So absent of doing those changes ourselves, we need to wait before we're
      # able to import a backup of our file into our own ActualBudget instance.
      package = pkgs.actual-server.overrideAttrs (oldAttrs: {
        src = pkgs.fetchFromGitHub {
          name = "actualbudget-actual-source";
          owner = "actualbudget";
          repo = "actual";
          tag = "v25.6.1";
          hash = "sha256-+6rMfFmqm7HLYMgmiG+DE2bH5WkIZxwTiy2L/CdZYEI=";
        };
      });
      settings = {
        port = cfg.port;
        hostname = "127.0.0.1";
        # ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB = "100";
        # ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB = "100";
        # ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB = "100";

        # Where server data is stored and backed up from.
        dataDir = "/mnt/storagebox/actual";
        
        # Prevent errors when the budget may eventually become large.
    
        # We only use password login.
        allowedLoginMethods = ["password"];
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
          "/" = {
            # Proxy all traffic straight through.
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };

        # Allow uploading media files up to 100 megabytes in size.
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };
  };
}