
{pkgs, ...}:

{
  config = {
    # Install neovim
    sys.software = [ pkgs.neovim ];
  };
}
