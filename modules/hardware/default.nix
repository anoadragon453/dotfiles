{ ... }:
{
    imports = [ 
        ./software.nix
        ./cpu.nix
        ./firmware.nix
        ./wifi.nix
        ./yubikey.nix
        ./disk.nix
        ./bluetooth.nix
        ./audio.nix
        ./gpu.nix
    ];
}
