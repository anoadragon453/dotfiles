{ pkgs, config, lib, ...}:
{
    imports = [
        ./core.nix
        ./development.nix
    ];
}
