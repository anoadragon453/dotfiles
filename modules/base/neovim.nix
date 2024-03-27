
{pkgs, ...}:

{
  config = {
    # Install neovim
    sys.software = [ pkgs.neovim ];

    # Alias vim to nvim
    environment.shellAliases = {
      vim = "nvim";
    };
  };
}
