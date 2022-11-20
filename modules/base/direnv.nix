{pkgs, config, lib, ...}:
with lib;
with pkgs;
let
  cfg = config.sys;
in {
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

    # support for flakes
    nixpkgs.overlays = [
      (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
    ];

  };
}