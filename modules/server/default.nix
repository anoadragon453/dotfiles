{...}:
{
  imports = [
    ./caddy.nix
    ./navidrome.nix
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
