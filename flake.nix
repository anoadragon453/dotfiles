{
  description = "anoa's system configuration";

  inputs = {
    # Reproducible developer environments with nix.
    devenv = {
      url = "github:cachix/devenv/v0.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific tweaks.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Official Nix Packages repository.
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Real-time audio prduction on NixOS.
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
        inputs.deploy-rs.overlay
        localpkgs
        extralib
        # Create an overlay that contains the 64-bit Linux version of devenv.
        # TODO: There's likely a more portable way of doing this...
        (self: super: { devenv = inputs.devenv.packages.x86_64-linux.devenv; } )
        # Use deploy-rs from the deploy-rs input, but take use the nixpkgs input for all
        # dependencies. Significantly speeds up build times of the deploy-rs package.
        (self: super: { deploy-rs = { inherit (nixpkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
      ];
    };

    # NixOS Modules common to all systems.
    commonModules = [
      ./modules
      # Needed due to `musnix` being evaluated in `real-time-audio.nix` on every system,
      # even though it's not needed.
      inputs.musnix.nixosModules.musnix
      inputs.sops-nix.nixosModules.sops
    ];

  in {
    devShell = lib.withDefaultSystems (sys: let
      pkgs = allPkgs."${sys}";
    in import ./shell.nix { inherit pkgs; });

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
          sys.virtualisation.virtualbox.enable = false;

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

          # Back up home directories using restic.
          sys.backup.restic = {
            enable = true;
            backupPasswordFileSecret = "restic";
            includedPaths = [ "/home" ];
            repository = "sftp://u220692-sub7@u220692-sub7.your-storagebox.de:23/restic/";
            extraOptions = [
              "sftp.command='ssh -p23 u220692-sub7@u220692-sub7.your-storagebox.de -i /home/user/.ssh/sops-ssh -s sftp'"
            ];
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

          # Use this SSH key as the age key to decrypt secrets with.
          sops.age.sshKeyPaths = [ "/home/user/.ssh/sops-ssh" ];

          sops.secrets = {
            restic = {
              sopsFile = ./secrets/personal_common/restic_backup;
              format = "binary";
            };
          };

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

          # Services on this machine.
          sys.server = {
            caddy.enable = true;

            navidrome = {
              enable = true;
              domain = "navidrome.amorgan.xyz";
              port = 8003;
              musicLibraryFilePath = "/mnt/music";
              logLevel = "info";
            };

            onlyoffice-document-server = {
              enable = true;
              domain = "onlyoffice.amorgan.xyz";
              port = 8002;
              jwtSecretFilePath = "onlyoffice-document-server-jwt-secret";
            };

            vaultwarden = {
              enable = true;
              domain = "p.amorgan.xyz";
              port = 8001;
              websocketPort = 3012;
              environmentFileSecret = "vaultwardenEnv";
              logLevel = "info";
            };
          };

          sops.secrets = {
            onlyoffice-document-server-jwt-secret = {
              restartUnits = [ "onlyoffice-docservice.service" ];
              sopsFile = ./secrets/plonkie/onlyoffice-document-server-jwt-secret;

              # It's actually just a plaintext file containing the secret.
              format = "binary";

              # Allow the OnlyOffice DocumentService to read the file.
              owner = "onlyoffice";
              group = "onlyoffice";
            };

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
