{
  description = "anoa's system configuration";

  inputs = {
    # Reproducible developer environments with nix.
    devenv.url = "github:cachix/devenv/v0.6.2";

    # Hardware-specific tweaks.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Official Nix Packages repository.
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Real-time audio prduction on NixOS.
    musnix.url = "github:musnix/musnix";

    # Deploy NixOS derivations to remote machines.
    deploy-rs.url = "github:serokell/deploy-rs";

    # Secrets management for NixOS deployments.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        # Create an overlay that contains the 64-bit Linux version of devenv.
        # TODO: There's likely a more portable way of doing this...
        (self: super: { devenv = inputs.devenv.packages.x86_64-linux.devenv; } )
      ];
    };

    # NixOS Modules common to all systems.
    commonModules = [
      ./modules
      # TODO: Remove the need for this to be here on a machine that doesn't need real-time audio
      # (i.e. my VMs)
      inputs.musnix.nixosModules.musnix
      inputs.sops-nix.nixosModules.sops
    ];

  in {
    devShell = lib.withDefaultSystems (sys: let
      pkgs = allPkgs."${sys}";
    in import ./shell.nix { inherit pkgs; });

    # packages = lib.mkSearchablePackages allPkgs;

    nixosConfigurations = {

      ## Personal devices

      moonbow = lib.mkNixOSConfig {
        name = "moonbow";
        system = "x86_64-linux";
        modules = commonModules ++ [
          ./modules
        ];
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
              groups = [ "adbusers" "audio" "docker" "networkmanager" "pipewire" "wheel" ];
              roles = ["development"];
              
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
          sys.biosType = "efi";

          sys.enableFlatpakSupport = true;
          sys.enablePrintingSupport = true;

          sys.desktop.gui.types = [ "gnome" ];

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

          sys.vpn.services = [ "mullvad" ];

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

          fileSystems."/run/media/user/Winblows" =
            { device = "/dev/disk/by-uuid/8028-9296";
              fsType = "exfat";
            };

          swapDevices =
            [ { device = "/dev/disk/by-uuid/66aa4315-bbd2-4872-8284-983d5f5be994"; }
            ];

        };
      };

      izzy = lib.mkNixOSConfig {
        name = "izzy";
        system = "x86_64-linux";
        modules = commonModules ++ [
          inputs.nixos-hardware.nixosModules.framework
        ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];

          # Not sure if this is needed
          #sys.hotfix.kernelVectorWarning = true; 

          #networking.useDHCP = lib.mkDefault true;
          #networking.interfaces.wlp170s0 = { useDHCP = true; };
          networking.networkmanager.enable = true;

          # Framework laptop needs at least 5.16 for working wifi/bluetooth
          sys.kernelPackage = pkgs.linuxPackages_latest;

          sys.virtualisation.docker.enable = true;
          sys.virtualisation.podman.enable = false;
          sys.virtualisation.virtualbox.enable = true;

          sys.user.users.user = {
              # TODO: Move adbusers into android.nix somehow
              groups = [ "adbusers" "audio" "docker" "networkmanager" "pipewire" "wheel" ];
              roles = ["development"];
              
              sshPublicKeys = [
                "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGVdcgCRUwCd83w5L+k5yhDHrLDF88GgDWdhvMqYAUiAAAAABHNzaDo="
              ];

              config = {
                email = "andrew@amorgan.xyz";
                name = "Andrew Morgan";
                signingKey = "0xA7E4A57880C3A4A9";
              };
          };

          sys.user.users.work = {
              # TODO: Move adbusers into android.nix somehow
              groups = [ "adbusers" "audio" "docker" "networkmanager" "pipewire" "wheel" ];
              roles = ["development"];
              
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
          sys.biosType = "efi";

          sys.enableFlatpakSupport = true;
          sys.enablePrintingSupport = true;

          sys.desktop.gui.types = [ "gnome" ];

          sys.desktop.kdeconnect.enable = true;
          sys.desktop.kdeconnect.implementation = "gsconnect";

          sys.hardware.audio.server = "pipewire";
          sys.desktop.realTimeAudio.enable = true;
          sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

          sys.hardware.bluetooth = true;
          sys.hardware.graphics.primaryGPU = "intel";
          sys.hardware.graphics.displayManager = "gdm";
          sys.hardware.graphics.desktopProtocols = [ "xorg" "wayland" ];
          sys.hardware.graphics.v4l2loopback = true;

          sys.thunderbird.customTempDirectory = "/tmp/thunderbird";
          sys.security.antivirus.clamav = {
            enable = true;
            pathsToExcludeRegex = [ "(/home/user|/proc|/nix)" ];
            pathsToIncludeOnAccess = [ "/home/work/Documents" "/home/work/Downloads" "/tmp/thunderbird" ];
          };

          sys.security.yubikey = {
            enable = true;
            legacySSHSupport = true;
          };
          sys.security.sshd.enable = false;

          # Require that all accounts type in the root password when using 'sudo', rather than their own.
          # This is a work-related security requirement.
          security.sudo.extraConfig = ''
            Defaults rootpw
          '';

          sys.vpn.services = [ "mullvad" "tailscale" ];

          services.postgresql.enable = true;

          # Disable fingerprint reader enabled by nixos-hardware's framework service.
          # Mostly because GDM doesn't interact well with the PAM rules set by it.
          services.fprintd.enable = false;

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";
          sys.bootloaderMountPoint = "/boot/efi";

          # Setup keyfile
          boot.initrd.secrets = {
            "/crypto_keyfile.bin" = null;
          };

          # Swap
          boot.initrd.luks.devices."luks-4c84c7eb-6ec2-428d-8f3e-82ce78c0f00b".device = "/dev/disk/by-uuid/4c84c7eb-6ec2-428d-8f3e-82ce78c0f00b";
          boot.initrd.luks.devices."luks-4c84c7eb-6ec2-428d-8f3e-82ce78c0f00b".keyFile = "/crypto_keyfile.bin";
          swapDevices =
            [ { device = "/dev/disk/by-uuid/3e9a5346-b193-4bf1-b805-1cd65cb1de87"; }
            ];

          # Root filesystem
          fileSystems."/" =
            { device = "/dev/disk/by-uuid/bda31b70-0bfb-4153-881e-98b57478241c";
              fsType = "ext4";
            };

          boot.initrd.luks.devices."luks-29870430-e228-4f4a-a39f-932382a517f6".device = "/dev/disk/by-uuid/29870430-e228-4f4a-a39f-932382a517f6";

          # Boot device
          fileSystems."/boot/efi" =
            { device = "/dev/disk/by-uuid/725D-C6E7";
              fsType = "vfat";
            };

        };
      };

      halfy_music = lib.mkNixOSConfig {
        name = "halfy_music";
        system = "x86_64-linux";
        modules = commonModules ++ [
          inputs.nixos-hardware.nixosModules.framework
        ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          # Some useful tips:
          #
          # - Available software packages can be found at https://search.nixos.org/packages?channel=unstable
          #   Note that we are using the unstable channel in the `inputs` of this flake.
          #
          # - Available NixOS options can be found under https://search.nixos.org/options?channel=unstable
          #   Options are typically how you configure system services/system-wide configuration.
          #
          # - The NixOS manual is: https://nixos.org/manual/nixos/unstable/
          #   The Nixpkgs (main package repository) manual is: https://nixos.org/manual/nixpkgs/unstable/
          #   NixHub can be used to find older versions of packages, though I find that this is typically
          #     not something I need: https://www.nixhub.io/
          #   https://zero-to-nix.com/ has really good, clear explanations of all of these concepts.
          #
          # - Desktop applications to be installed are specified under `modules/desktop/applications.nix`.
          #
          # - Base software (what would be needed by all systems, desktop or server) are specified
          #   in `modules/base/software.nix`.
          #
          # - All of the `sys.*` options in this file are defined in this repo in the various modules/* folders.
          #   Depending of their values, the nix code in this repo will set various NixOS module options (which
          #   again, you can find the possible options using the link above). You can also just set the NixOS
          #   module options in this file directly. For instance, to install and enable postgres on this system,
          #   just put `services.postgresql.enable = true` below.

          # TODO: Find the appropriate kernel modules for your hardware from the `hardware-configuration.nix` file
          # from your initial NixOS installation.
          boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];

          networking.networkmanager.enable = true;

          # Use real-time kernel for audio production.
          sys.kernelPackage = pkgs.linuxPackages-rt_latest;

          sys.user.users.user = {
              groups = [ "audio" "networkmanager" "pipewire" "wheel" ];
              roles = [];
              
              sshPublicKeys = [];
          };

          # TODO: Enter system details.
          sys.cpu.type = "intel";
          sys.cpu.cores = 8;
          sys.cpu.threadsPerCore = 8;
          sys.biosType = "efi";

          sys.enableFlatpakSupport = true;
          sys.enablePrintingSupport = false;

          sys.desktop.gui.types = [ "gnome" ];

          sys.desktop.kdeconnect.enable = true;
          sys.desktop.kdeconnect.implementation = "gsconnect";

          # TODO: Enter soundcard PCI device ID (use `lspci`)
          sys.hardware.audio.server = "pipewire";
          sys.desktop.realTimeAudio.enable = true;
          sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

          # TODO: More hardware details. Note: don't remove "xorg" below, it's currently required.
          sys.hardware.bluetooth = true;
          sys.hardware.graphics.primaryGPU = "intel";
          sys.hardware.graphics.displayManager = "gdm";
          sys.hardware.graphics.desktopProtocols = [ "xorg" "wayland" ];
          sys.hardware.graphics.v4l2loopback = true;

          # TODO: Do you need a yubikey setup on this system?
          sys.security.yubikey = {
            enable = true;
            # If you are using SK-type SSH keys, then set this to `false`. If you don't know what that this, keep this as `true` :)
            legacySSHSupport = true;
          };
          sys.security.sshd.enable = false;

          sys.vpn.services = [];

          # TODO: Whether to enable fingerprint login support.
          services.fprintd.enable = false;

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";
          sys.bootloaderMountPoint = "/boot/efi";
          
          # TODO: You'll need to manually specify your hardware devices. You should be able to find this info from the `hardware-configuration.nix`
          # file from your initial NixOS installation.
          fileSystems."/" =
            { device = "/dev/sda1";
              fsType = "ext4";
            };
        };
      };

      ## Server infrastructure

      plonkie = lib.mkNixOSConfig {
        name = "plonkie";
        system = "x86_64-linux";
        modules = commonModules ++ [
          ./modules/vm/qemu-guest.nix
        ];
        inherit nixpkgs allPkgs;
        cfg = {
          # TODO: Enable across all machines?
          zramSwap.enable = true;
          boot.tmp.cleanOnBoot = true;

          boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
          boot.initrd.kernelModules = [ "nvme" ];

          # TODO: Switch this system to use systemd-boot or remove/fix grub
          # support in dotfiles.
          sys.bootloader = "grub";
          # Currently this is not set in disk.nix.
          boot.loader.grub.device = "/dev/sda";

          sys.user.root.sshPublicKeys = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGVdcgCRUwCd83w5L+k5yhDHrLDF88GgDWdhvMqYAUiAAAAABHNzaDo="
          ];

          sys.cpu.type = "intel";
          sys.cpu.cores = 1;
          sys.cpu.threadsPerCore = 2;
          sys.biosType = "efi";

          sys.security.sshd.enable = true;

          # Services this machine is hosting.
          sys.server = {
            caddy.enable = true;

            vaultwarden = {
              enable = true;
              domain = "p.amorgan.xyz";
              port = 8001;
              websocketPort = 3012;
              environmentFilePath = "vaultwardenEnv";
            };
          };

          sops.secrets = {
            vaultwardenEnv = {
              restartUnits = [ "vaultwarden.service" ];
              sopsFile = ./secrets/plonkie/vaultwarden.env;
              format = "dotenv";
            };
          };

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";
          sys.bootloaderMountPoint = "/boot/efi";

          fileSystems."/" =
            { device = "/dev/sda1";
              fsType = "ext4";
            };

        };
      };
    };

    # Configuration on deploying server infrastructure using deploy-rs.
    deploy.nodes.plonkie = {
      sshOpts = [ ];
      hostname = "78.47.36.247";
      profiles = {
        system = {
          sshUser = "root";
          path =
            inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.plonkie;
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
