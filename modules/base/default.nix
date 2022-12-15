{pkgs, config, lib, ...}:
{
    imports = [
        ./android.nix
        ./software.nix
        ./direnv.nix
        ./disk.nix
        ./flatpak.nix
        ./kernel.nix
        ./neovim.nix
        ./nix.nix
        ./printing.nix
        ./syst.nix
        ./regional.nix
        ./security.nix
        ./shell.nix
        ./virtualisation.nix
        ./vpn.nix
    ];
}
