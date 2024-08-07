{
  description = "anoa's system configuration";

  inputs = {
    # Reproducible developer environments with nix.
    devenv = {
      url = "github:cachix/devenv/v0.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Management of user-level configuration.
    home-manager = {
      url = "github:nix-community/home-manager";
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
    # We need to import the deploy-rs flake as it includes the deploy-rs
    # activation script.
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

    # Create a custom instance of nixpkgs with the deploy-rs overlay in use, but
    # the deploy-rs *package* from nixpkgs - thus allowing use of nixpkgs'
    # binary cache for the deploy-rs package.
    deployPkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [
        inputs.deploy-rs.overlays.default
        (self: super: { deploy-rs = { inherit (allPkgs."x86_64-linux") deploy-rs; lib = super.deploy-rs.lib; }; })
      ];
    };

    allPkgs = lib.mkPkgs {
      inherit nixpkgs; 
      cfg = {
        allowUnfree = true;
      };
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
      inputs.sops-nix.nixosModules.sops
    ];

    # The SSH keys allowed to SSH into my personal devices.
    personalDeviceSshPublicKeys = [
      # Personal Yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGVdcgCRUwCd83w5L+k5yhDHrLDF88GgDWdhvMqYAUiAAAAABHNzaDo="
      # Work Yubikey
      (builtins.concatStringsSep "" [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2IeWa2q5ZtiZSdZw6ZCwTmaUyEfwaYl9Bef49Gj2E+p2OVu2Zqc9YDOtZldvturwWcFxqNy8shCed5vaGlQgUe2Q+"
        "y0vxPtMTbw/6qVYd1FDXAqPk+CDwBbtP3iD3ovki8zvOZapoeUNLtLX4U1xn4eikgL4+NdRhElZqfL7VCfD7nkKp4XUVXEcKqatYphcGRBKSqiMkRhTieaOpSHxMhTloN"
        "ZYViVFa6ugQgZVDQ7xYO02yAYczI2Uv7JH4vRS75Es+aLQG8a0W29V2ZW2OBuHRjDg0kBvR0M2KNORWC1d9Tt4P1BF/r6FDfhqWd7Zd+QNlH9/XdwuJDaha+g6bLQdC60"
        "b+vo2lGE4Cn6i3srvXWwhv/yiP+SDekzSoEUwB+kcBgc05IARQPA8Am3r3NtTqtb/GJbj8U+8Q10mA7NJ8W/IZS8gCmbxVrkygAZgAHM+fDiT2Lh8KPrVih5Xt+n9kwZG"
        "TklxBlfgrllzDszvrZRmLzZj8Zw1MdYwJFqes8lV3WILXpw2E3/iJSiT08/igdgQDLHywQbXd6iw18XciZa7JSxwwvxJ6h16b9JiXXyXSxMAJmDJn92MAYxGQ1hzGuT7g"
        "MQ/M65l8qCs5Ra6fhXiwfax9CtcexmhxYriziIz0MySFTIw5wk6Ppvaz6GdKT4Y+FFTKA19GH1l5Fw=="
      ])
    ];
    # The SSH keys allowed to SSH into my server infrastructure.
    infrastructureSshPublicKeys = personalDeviceSshPublicKeys ++ [
      # Sops SSH key (used for secrets en/decryption and auth'ing to server infrastructure).
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqiV558AS8OkEZAnxTMsRbH4sPMtK/Lou5PIJnmvkvd user@izzy"
    ];

  in {
    # TODO: Refactor this to devShell.${sys}.default somehow.
    devShell = lib.withDefaultSystems (sys: let
      pkgs = allPkgs."${sys}";
    in import ./shell.nix { inherit pkgs; });

    nixosConfigurations = {

      ## Personal devices

      moonbow = lib.mkNixOSConfig {
        name = "moonbow";
        system = "x86_64-linux";
        modules = commonModules ++ [
          # Enable real time audio on this system for music production.
          inputs.musnix.nixosModules.musnix
          ./modules/desktop/real-time-audio.nix

          inputs.home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = {
              user = {
                home.stateVersion = "23.11";
                imports = [ modules/home-manager ];
              };
            };
          }
        ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];

          # TODO: I had to override the realtime kernel defined in musnix as the
          # realtime patch currently fails to apply.
          sys.kernelPackage = pkgs.lib.mkDefault pkgs.linuxPackages_latest;

          networking.interfaces."enp8s0" = { useDHCP = true; };
          networking.networkmanager.enable = true;

          sys.user.users.user = {
            # TODO: Move adbusers into android.nix somehow
            groups = [ "adbusers" "audio" "docker" "networkmanager" "pipewire" "wheel" ];
            roles = ["development"];
            sshPublicKeys = personalDeviceSshPublicKeys;

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
            repository = "sftp://u220692-sub7@u220692-sub7.your-storagebox.de:23/";
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
          sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

          sys.hardware.bluetooth = true;
          sys.hardware.graphics.primaryGPU = "amd";
          sys.hardware.graphics.amd.rocm.enable = true;
          sys.hardware.graphics.displayManager = "gdm";
          sys.hardware.graphics.desktopProtocols = [ "xorg" "wayland" ];
          sys.hardware.graphics.v4l2loopback = true;

          # Use this SSH key as the age key to decrypt secrets with.
          sops.age.sshKeyPaths = [ "/home/user/.ssh/sops-ssh" ];

          sops.secrets = {
            restic = {
              sopsFile = ./secrets/personal_common/restic_backup;
              format = "binary";
            };
          };

          sys.security.yubikey = {
            enable = true;
            legacySSHSupport = false;
          };
          sys.security.sshd.enable = false;

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";

          sys.vpn.services = [ "mullvad" ];

          # Open LUKS encrypted partitions and make available as /dev/mapper devices.
	        # Root and /boot.
          boot.initrd.luks.devices."luks-2dbafbac-35bd-43d4-a8ff-5af82cd4b26c".device = "/dev/disk/by-uuid/2dbafbac-35bd-43d4-a8ff-5af82cd4b26c";
          # Swap.
          boot.initrd.luks.devices."luks-cbfbc367-a93a-4d21-984f-c09f302528e1".device = "/dev/disk/by-uuid/cbfbc367-a93a-4d21-984f-c09f302528e1";

          # Mount /dev/mapper devices to the filesystem.
          fileSystems."/boot" =
          { device = "/dev/disk/by-uuid/9447-C14A";
            fsType = "vfat";
          };

          fileSystems."/" =
          { device = "/dev/disk/by-uuid/7dcef2f7-4d44-4fff-8a60-19505454300e";
            fsType = "ext4";
          };

          swapDevices =
          [ { device = "/dev/disk/by-uuid/95916c33-ccd9-449f-ae3d-cccbcb88936f"; }
          ];

          # Mount other devices.
          fileSystems."/run/media/user/Steam" =
            { device = "/dev/disk/by-uuid/76240c8a-cf38-4663-9d0a-bf16b416f601";
              fsType = "ext4";
            };

          fileSystems."/run/media/user/Winblows" =
            { device = "/dev/disk/by-uuid/8028-9296";
              fsType = "exfat";
            };

        };
      };

      izzy = lib.mkNixOSConfig {
        name = "izzy";
        system = "x86_64-linux";
        modules = commonModules ++ [
          inputs.nixos-hardware.nixosModules.framework-11th-gen-intel

          inputs.home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = {
              user = {
                home.stateVersion = "23.11";
                imports = [ modules/home-manager ];
              };
              work = {
                home.stateVersion = "23.11";
                imports = [ modules/home-manager ];
              };
            };
          }
        ];
        inherit nixpkgs allPkgs;
        cfg = let 
          pkgs = allPkgs.x86_64-linux;
        in {
          boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];

          sys.kernelPackage = pkgs.linuxPackages;

          networking.networkmanager.enable = true;

          sys.user.users.user = {
            # TODO: Move adbusers into android.nix somehow
            groups = [ "adbusers" "audio" "docker" "networkmanager" "pipewire" "wheel" ];
            roles = ["development"];
            sshPublicKeys = personalDeviceSshPublicKeys;

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

            sshPublicKeys = personalDeviceSshPublicKeys;

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
            repository = "sftp://u220692-sub7@u220692-sub7.your-storagebox.de:23/";
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
          #sys.desktop.realTimeAudio.soundcardPciId = "00:1f.3";

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

          # Set up a very temp sliding sync proxy for trinity work.
          services.matrix-sliding-sync = {
            enable = true;
            settings = {
              SYNCV3_SERVER = "http://127.0.0.1:8081";
              SYNCV3_BINDADDR = "0.0.0.0:8181";
            };
            environmentFile = builtins.toFile "sliding-sync-env" ''
              SYNCV3_SECRET=e83246af3096dadc99372406c8f1f41de72c1e0591e3d0d54435d7eb5a28d520
            '';
            createDatabase = true;
          };

          # Expose both the homeserver's well-known file (which points to the
          # proxy) and the sliding sync proxy itself to my network.
          networking.firewall.allowedTCPPorts = [ 8081 8181 ];

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

          boot.initrd.luks.devices."luks-29870430-e228-4f4a-a39f-932382a517f6".device = "/dev/disk/by-uuid/29870430-e228-4f4a-a39f-932382a517f6";

          fileSystems = {
            # Root filesystem
            "/" =
              { device = "/dev/disk/by-uuid/bda31b70-0bfb-4153-881e-98b57478241c";
                fsType = "ext4";
              };

            # Boot device
            "/boot/efi" =
              { device = "/dev/disk/by-uuid/725D-C6E7";
                fsType = "vfat";
              };
          };
        };
      };

      ## Server infrastructure

      plonkie = lib.mkNixOSConfig {
        name = "plonkie";
        system = "x86_64-linux";
        modules = commonModules ++ [
          ./modules/vm/qemu-guest.nix
          
          # Server-specific configuration.
          ./modules/server
        ];
        inherit nixpkgs allPkgs;
        cfg = let
          pkgs = allPkgs.x86_64-linux;
        in {
          boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
          boot.initrd.kernelModules = [ "nvme" ];

          # TODO: Switch this system to use systemd-boot or remove/fix grub
          # support in dotfiles.
          sys.bootloader = "grub";
          # Currently this is not set in disk.nix.
          boot.loader.grub.device = "/dev/sda";

          sys.user.root.sshPublicKeys = infrastructureSshPublicKeys;

          sys.cpu.type = "intel";
          sys.cpu.cores = 1;
          sys.cpu.threadsPerCore = 2;
          sys.biosType = "efi";

          sys.security.sshd.enable = true;

          # Disable KVM support on this machine as it's not needed. This leads
          # to libvirt not being installed, which saves disk space.
          sys.cpu.kvm = false;

          # No need to update the firmware of cloud hosting providers' VMs.
          services.fwupd.enable = nixpkgs.lib.mkForce false;

          # Services on this machine.
          sys.server = {
            acme.email = "andrew@amorgan.xyz";

            immich = {
              enable = true;
              domain = "i.amorgan.xyz";
              port = 8006;
              metricsPortServer = 8009;
              metricsPortMicroservices = 8010;
              storagePath = "/mnt/storagebox/media/immich";
              logLevel = "log";
            };

            mealie = {
              enable = true;
              domain = "r.amorgan.xyz";
              storagePath = "/mnt/storagebox/mealie";
              logLevel = "INFO";
              port = 8007;
            };

            navidrome = {
              enable = true;
              domain = "navidrome.amorgan.xyz";
              port = 8001;
              musicLibraryFilePath = "/mnt/storagebox/media/music";
              logLevel = "info";
            };

            paperless = {
              enable = true;
              port = 8011;
              domain = "docs.amorgan.xyz";
              superuserPasswordFilePath = "paperless-superuser-password";
              appDataFilePath = "/mnt/storagebox/paperless/appdata";
              documentsFilePath = "/mnt/storagebox/paperless/documents";
            };

            peertube = {
              enable = true;
              domain = "v.amorgan.xyz";
              httpPort = 8005;
              peertubeSecretFilePath = "peertube-secret";
            };

            postgresql.backups = {
              enable = true;
              backupLocationFilePath = "/mnt/storagebox/postgresql-backups";
            };

            vaultwarden = {
              enable = true;
              domain = "p.amorgan.xyz";
              port = 8004;
              websocketPort = 3012;
              environmentFileSecret = "vaultwardenEnv";
              logLevel = "info";
            };
          };

          sops.secrets = {
            paperless-superuser-password = {
              sopsFile = ./secrets/plonkie/paperless-superuser-password;

              # It's actually just a plaintext file containing the secret.
              format = "binary";

              # Allow the Paperless service to read the file.
              owner = "paperless";
              group = "paperless";
            };

            peertube-secret = {
              restartUnits = [ "peertube.service" ];
              sopsFile = ./secrets/plonkie/peertube-secret;

              # It's actually just a plaintext file containing the secret.
              format = "binary";

              # Allow the PeerTube service to read the file.
              owner = "peertube";
              group = "peertube";
            };

            vaultwardenEnv = {
              restartUnits = [ "vaultwarden.service" ];
              sopsFile = ./secrets/plonkie/vaultwarden.env;
              format = "dotenv";
            };

            # A private component of a SSH Key to give access to the media
            # folder on my hetzner storagebox. The decrypted version ends up at
            # /run/secrets/storagebox-media. SSHFS should use that path.
            storagebox-media = {
              sopsFile = ./secrets/plonkie/storagebox-media;
              format = "binary";
            };

            # A private component of a SSH Key to give access to the mealie
            # folder on my hetzner storagebox. The decrypted version ends up at
            # /run/secrets/storagebox-mealie. SSHFS should use that path.
            storagebox-mealie = {
              sopsFile = ./secrets/plonkie/storagebox-mealie;
              format = "binary";
            };

            # A private component of a SSH Key to give access to the paperless
            # folder on my hetzner storagebox. The decrypted version ends up at
            # /run/secrets/storagebox-paperless. SSHFS should use that path.
            storagebox-paperless = {
              sopsFile = ./secrets/plonkie/storagebox-paperless;
              format = "binary";
            };

            # A private component of a SSH Key to give access to the directory
            # containing postgresql backups on my hetzner storagebox. The
            # decrypted version ends up at /run/secrets/storagebox-postgresql-plonkie.
            # SSHFS should use that path.
            storagebox-postgresql-plonkie = {
              sopsFile = ./secrets/plonkie/storagebox-postgresql-plonkie;
              format = "binary";
            };
          };
          # Set these to an empty list to tell sops not to try and look for
          # any ssh or gpg keys to turn into age keys.
          sops.age.sshKeyPaths = [];
          sops.gnupg.sshKeyPaths = [];
          # The private key to decrypt sops secrets with.
          # This file must be placed here manually.
          sops.age.keyFile = "/var/lib/sops-nix/key.txt";

          # Disable default disk layout magic and just use the declarations below.
          sys.diskLayout = "disable";
          sys.bootloaderMountPoint = "/boot/efi";

          fileSystems."/" = {
            device = "/dev/sda1";
              fsType = "ext4";
            };

          # Mount my hetzner storagebox for media.
          # Note: This will only mount on live systems, not VMs.
          fileSystems."/mnt/storagebox/media" = {
            device = "u220692-sub4@u220692-sub4.your-storagebox.de:/home";
            fsType = "sshfs";
            options =
              [ # Filesystem options
                "allow_other"          # for non-root access
                "_netdev"              # this is a network fs

                # We don't mount on demand, as that will cause services like navidrome to fail
                # as the share doesn't yet exist.
                #"x-systemd.automount" # mount on demand, rather than boot

                #"debug"               # print debug logging
                                       # warning: this causes the one-shot service to never exit

                # SSH options
                "StrictHostKeyChecking=no"  # prevent the connection from failing if the host's key hasn't been trusted yet
                "ServerAliveInterval=15" # keep connections alive
                "Port=23"
                "IdentityFile=/run/secrets/storagebox-media"
              ];
          };

          # Mount my hetzner storagebox for mealie.
          # Note: This will only mount on live systems, not VMs.
          fileSystems."/mnt/storagebox/mealie" = {
            device = "u220692-sub5@u220692-sub5.your-storagebox.de:/home";
            fsType = "sshfs";
            options =
              [ # Filesystem options
                "allow_other"          # for non-root access
                "_netdev"              # this is a network fs

                # We don't mount on demand, as that will cause services like navidrome to fail
                # as the share doesn't yet exist.
                #"x-systemd.automount" # mount on demand, rather than boot

                #"debug"               # print debug logging
                                       # warning: this causes the one-shot service to never exit

                # SSH options
                "StrictHostKeyChecking=no"  # prevent the connection from failing if the host's key hasn't been trusted yet
                "ServerAliveInterval=15" # keep connections alive
                "Port=23"
                "IdentityFile=/run/secrets/storagebox-mealie"
              ];
          };

          # Mount my hetzner storagebox for mealie.
          # Note: This will only mount on live systems, not VMs.
          fileSystems."/mnt/storagebox/paperless" = {
            device = "u220692-sub8@u220692-sub8.your-storagebox.de:/home";
            fsType = "sshfs";
            options =
              [ # Filesystem options
                "allow_other"          # for non-root access
                "_netdev"              # this is a network fs

                # We don't mount on demand, as that will cause services like navidrome to fail
                # as the share doesn't yet exist.
                #"x-systemd.automount" # mount on demand, rather than boot

                #"debug"               # print debug logging
                                       # warning: this causes the one-shot service to never exit

                # SSH options
                "StrictHostKeyChecking=no"  # prevent the connection from failing if the host's key hasn't been trusted yet
                "ServerAliveInterval=15" # keep connections alive
                "Port=23"
                "IdentityFile=/run/secrets/storagebox-paperless"
              ];
          };

          # Mount my hetzner storagebox for postgresql backups.
          # Note: This will only mount on live systems, not VMs.
          fileSystems."/mnt/storagebox/postgresql-backups" = {
            device = "u220692-sub6@u220692-sub6.your-storagebox.de:/home";
            fsType = "sshfs";
            options =
              [ # Filesystem options
                "allow_other"          # for non-root access
                "_netdev"              # this is a network fs

                # We don't mount on demand, as that will cause services like navidrome to fail
                # as the share doesn't yet exist.
                #"x-systemd.automount" # mount on demand, rather than boot

                #"debug"               # print debug logging
                                       # warning: this causes the one-shot service to never exit

                # SSH options
                "StrictHostKeyChecking=no"  # prevent the connection from failing if the host's key hasn't been trusted yet
                "ServerAliveInterval=15" # keep connections alive
                "Port=23"
                "IdentityFile=/run/secrets/storagebox-postgresql-plonkie"
              ];
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
            deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.plonkie;
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
