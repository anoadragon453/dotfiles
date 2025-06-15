{...}:
{
  imports = [
    ./acme.nix
    ./actual.nix
    ./immich.nix
    ./mealie.nix
    ./navidrome.nix
    ./nginx.nix
    ./onlyoffice-document-server.nix
    ./paperless.nix
    ./peertube.nix
    ./postgresql.nix
    ./vaultwarden.nix
  ];

  options.sys.server = {
    details = {
      "plonkie" = {
        host = "78.47.36.247";
      };
    };
  };
}
