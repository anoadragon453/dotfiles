{config, lib, ...}:

let
  cfg = config.sys.server.open-webui;
in {
  options.sys.server.open-webui = {
    enable = lib.mkEnableOption "open-webui Music Streaming Server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the open-webui instance on";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port to listen on for incoming web and API connections";
    };

    openAIApiKeySecretFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The OpenAI API Key sops secret";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      open-webui = {
        enable = true;

        port = cfg.port;

        environment = {
          ENABLE_SIGNUP = "false";

          # Disable Ollama support as we're only using OpenAI as a backend for now.
          ENABLE_OLLAMA_API = "false";
        };
        environmentFile = config.sops.secrets."${cfg.openAIApiKeySecretFilePath}".path;
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