{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
    nixpkgs.config.allowUnfree = true;
    
    nix = {
        settings = {
            max-jobs = cfg.cpu.cores * cfg.cpu.threadsPerCore * cfg.cpu.sockets;
            auto-optimise-store = true;
        };

        extraOptions = ''
            # Enable flakes
            experimental-features = nix-command flakes

            # Prevent nix-direnv packages from being garbage collected.
            # From https://github.com/nix-community/nix-direnv README
            keep-outputs = true
            keep-derivations = true
        '';
        gc = {
            automatic = true;
            options = "--delete-older-than 10d";
        };
    };
}
