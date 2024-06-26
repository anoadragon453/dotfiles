{pkgs, lib, ...}:
with lib;
with pkgs;
{
  config = {
    sys.software = [ direnv nix-direnv ];

    # Necessary configuration for nix-direnv.
    # From https://github.com/nix-community/nix-direnv#via-configurationnix-in-nixos
    environment.pathsToLink = [
      "/share/nix-direnv"
    ];
    sys.user.allUsers.files = {
      direnvSettings = {
        path = ".direnvrc";
        text = ''
          source /run/current-system/sw/share/nix-direnv/direnvrc
        '';
      };

      zshSettingsDirenvSource = {
        path = ".zshrc";
        text = ''
          eval "$(direnv hook zsh)"
        '';
      };
    };
  };
}