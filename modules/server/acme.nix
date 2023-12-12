{config, lib, ...}:

let
  cfg = config.sys.server.acme;
in {
  options.sys.server.acme = {
    email = lib.mkOption {
      type = lib.types.str;
      description = "The email to use when registering TLS certs through ACME";
    };
  };

  config = {
    # Configure an email for ACME and accept the terms, allowing us to receive
    # TLS certificates.
    security.acme = {
      defaults.email = cfg.email;
      acceptTerms = true;
    };
  };
}