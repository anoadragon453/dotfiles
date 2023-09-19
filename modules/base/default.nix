{pkgs, config, lib, ...}:
{
    imports = [
        ./android.nix
        ./antivirus.nix
        ./backup.nix
        ./software.nix
        ./direnv.nix
        ./disk.nix
        ./flatpak.nix
        ./kernel.nix
        ./neovim.nix
        ./network.nix
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
