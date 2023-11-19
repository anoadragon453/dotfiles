{...}:
{
  imports = [
    ./acme.nix
    ./caddy.nix
    ./navidrome.nix
    ./nginx.nix
    ./onlyoffice-document-server.nix
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
