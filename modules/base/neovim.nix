
{pkgs, config, lib, ...}:
with lib;
with pkgs;
let
  cfg = config.sys;
in {
  config = {
    # Install neovim
    sys.software = [ neovim ];

    # Alias vim to nvim
    environment.shellAliases = {
      vim = "nvim";
    };
  };
}
