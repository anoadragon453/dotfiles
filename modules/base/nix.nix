{config, ...}:
let
    cfg = config.sys;
in {
    nix = {
        settings = {
            max-jobs = cfg.cpu.cores * cfg.cpu.threadsPerCore * cfg.cpu.sockets;
            auto-optimise-store = true;

            # Set up trusted Nix binary cache servers.
            substituters = [
                # The official NixOS binary cache.
                "https://cache.nixos.org"
                # A binary cache for builds of devenv.
                "https://devenv.cachix.org"
            ];
            trusted-public-keys = [
                "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            ];
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
