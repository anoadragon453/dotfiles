{...}:
{
  imports = [
    ./acme.nix
    ./mealie.nix
    ./navidrome.nix
    ./nginx.nix
    ./onlyoffice-document-server.nix
    ./peertube.nix
    ./tandoor-recipes.nix
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
