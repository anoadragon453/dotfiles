{
  description = "anoa's system configuration";

  inputs = {
    # TODO: Add https://github.com/NixOS/nixos-hardware?
    nixpkgs.url = "nixpkgs/nixos-unstable";
    musnix  = { url = "github:musnix/musnix"; };
  };

  outputs = inputs @ {self, nixpkgs, ... }:
  let
    lib = import ./lib;
    localpkgs = import ./pkgs;
    extralib = self: super: import ./lib/extrafn.nix;

    allPkgs = lib.mkPkgs { 
      inherit nixpkgs; 
      cfg = { allowUnfree = true; };
      overlays = [
        localpkgs
        extralib
      ];
    };

  in {
    devShell = lib.withDefaultSystems (sys: let
      pkgs = allPkgs."${sys}";
    in import ./shell.nix { inherit pkgs; });

    packages = lib.mkSearchablePackages allPkgs;

    nixosConfigurations = {
      moonbow = lib.mkNixOSConfig {
        name = "moonbow";
        system = "x86_64-linux";
        modules = [ ./modules inputs.musnix.nixosModules.musnix ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];

          # Not sure if this is needed
          #sys.hotfix.kernelVectorWarning = true; 

          networking.interfaces."enp8s0" = { useDHCP = true; };
          networking.networkmanager.enable = true;

          # Use real-time kernel for audio production.
          sys.kernelPackage = pkgs.linuxPackages-rt_latest;

          sys.virtualisation.docker.enable = true;

          sys.user.users.user = {
              # TODO: Move adbusers into android.nix somehow
              groups = [ "adbusers" "audio" "docker" "networkmanager" "wheel" ];
              roles = ["development"];
              shell = "zsh";
              
              sshPublicKeys = [
                "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGVdcgCRUwCd83w5L+k5yhDHrLDF88GgDWdhvMqYAUiAAAAABHNzaDo="
              ];

              config = {
                email = "andrew@amorgan.xyz";
                name = "Andrew Morgan";
                signingKey = "0xA7E4A57880C3A4A9";
              };
          };

          sys.cpu.type = "intel";
          sys.cpu.cores = 8;
          sys.cpu.threadsPerCore = 8;
          sys.cpu.sensorCommand = ''sensors | grep "Tctl:" | awk '{print $2}' '';
          sys.biosType = "efi";

          sys.enableFlatpakSupport = true;
          sys.enablePrintingSupport = true;

          sys.desktop.gui.type = "gnome";

          sys.desktop.kdeconnect.enable = true;
          sys.desktop.kdeconnect.implementation = "gsconnect";

          sys.hardware.audio.server = "pipewire";
          sys.desktop.realTimeAudio.enable = true;
          sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

          sys.hardware.bluetooth = true;
          sys.hardware.graphics.primaryGPU = "amd";
          sys.hardware.graphics.amd.rocm.enable = true;
          sys.hardware.graphics.displayManager = "gdm";
          sys.hardware.graphics.desktopProtocols = [ "xorg" "wayland" ];
          sys.hardware.graphics.v4l2loopback = true;
          sys.hardware.graphics.gpuSensorCommand = ''sensors | grep "junction:" | awk '{print $2}' '';

          sys.security.yubikey = {
            enable = true;
            legacySSHSupport = false;
          };
          sys.security.sshd.enable = false;

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";
          sys.bootloaderMountPoint = "/boot/efi";

          # Setup luks full-disk encryption
          boot.initrd.secrets = {
            "/crypto_keyfile.bin" = null;
          };

          boot.initrd.luks.devices."luks-306a410d-8a3b-4ddf-97ad-b39f176a01d4".device = "/dev/disk/by-uuid/306a410d-8a3b-4ddf-97ad-b39f176a01d4";

          # Enable swap on luks
          boot.initrd.luks.devices."luks-50328598-1b0f-4ba9-9b1b-ea896dcab44b".device = "/dev/disk/by-uuid/50328598-1b0f-4ba9-9b1b-ea896dcab44b";
          boot.initrd.luks.devices."luks-50328598-1b0f-4ba9-9b1b-ea896dcab44b".keyFile = "/crypto_keyfile.bin";

          fileSystems."/" =
            { device = "/dev/disk/by-uuid/cd59f0ed-b749-4c14-8cee-2de37b6b166a";
              fsType = "ext4";
            };

          fileSystems."/boot/efi" =
            { device = "/dev/disk/by-uuid/601A-8328";
              fsType = "vfat";
            };

          fileSystems."/run/media/user/Steam" =
            { device = "/dev/disk/by-uuid/76240c8a-cf38-4663-9d0a-bf16b416f601";
              fsType = "ext4";
            };

          swapDevices =
            [ { device = "/dev/disk/by-uuid/66aa4315-bbd2-4872-8284-983d5f5be994"; }
            ];

        };
      };

      izzy = lib.mkNixOSConfig {
        name = "izzy";
        system = "x86_64-linux";
        modules = [ ./modules inputs.musnix.nixosModules.musnix ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          # TODO
          boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];

          # Not sure if this is needed
          #sys.hotfix.kernelVectorWarning = true; 

          # TODO
          networking.interfaces."enp8s0" = { useDHCP = true; };
          networking.networkmanager.enable = true;

          # Use real-time kernel for audio production.
          sys.kernelPackage = pkgs.linuxPackages-rt_latest;

          sys.virtualisation.docker.enable = true;

          sys.user.users.user = {
              # TODO: Move adbusers into android.nix somehow
              groups = [ "adbusers" "audio" "docker" "networkmanager" "wheel" ];
              roles = ["development"];
              shell = "zsh";
              
              sshPublicKeys = [
                "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGVdcgCRUwCd83w5L+k5yhDHrLDF88GgDWdhvMqYAUiAAAAABHNzaDo="
              ];

              config = {
                email = "andrew@amorgan.xyz";
                name = "Andrew Morgan";
                signingKey = "0xA7E4A57880C3A4A9";
              };
          };

          sys.cpu.type = "intel";
          sys.cpu.cores = 8;
          sys.cpu.threadsPerCore = 8;
          sys.cpu.sensorCommand = ''sensors | grep "Tctl:" | awk '{print $2}' '';
          sys.biosType = "efi";

          sys.enableFlatpakSupport = true;
          sys.enablePrintingSupport = true;

          sys.desktop.gui.type = "gnome";

          sys.desktop.kdeconnect.enable = true;
          sys.desktop.kdeconnect.implementation = "gsconnect";

          sys.hardware.audio.server = "pipewire";
          # TODO
          sys.desktop.realTimeAudio.enable = true;
          sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

          sys.hardware.bluetooth = true;
          sys.hardware.graphics.primaryGPU = "intel";
          sys.hardware.graphics.displayManager = "lightdm";
          sys.hardware.graphics.desktopProtocols = [ "xorg" "wayland" ];
          sys.hardware.graphics.v4l2loopback = true;
          sys.hardware.graphics.gpuSensorCommand = ''sensors | grep "junction:" | awk '{print $2}' '';

          sys.security.yubikey = {
            enable = true;
            legacySSHSupport = true;
          };
          sys.security.sshd.enable = false;

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "vm";
          sys.bootloaderMountPoint = "/boot/efi";

          # TODO

        };
      };
    };
  };
}
