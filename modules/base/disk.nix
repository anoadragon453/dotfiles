{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
   options.sys = {
    diskLayout = mkOption {
      type = types.enum [ "btrfs-crypt" "vm" "disable" ];
      description = "This is the layout of the disk used by the system.";
      default = "btrfs-crypt";
    };

    bootloader = mkOption {
      type = types.enum [ "grub" "systemd-boot" ];
      description = "The boot loader used to boot the system";
      default = "systemd-boot";
    };

    bootloaderMountPoint = mkOption {
      type = types.str;
      description = "The directory the boot loader is mounted at.";
      default = "/boot";
    };

    biosType = mkOption {
      type = types.enum [ "efi" "bios"];
      description = "Specify the bios type of the machine";
    };

    bootLogLevel = mkOption {
      type = types.ints.unsigned;
      description = "Log level of the kernel console output. Must be 0 to 7. 3 being errors only";
      default = 3;
    };

   };

   config = {
    boot.loader.systemd-boot.enable = cfg.bootloader == "systemd-boot";
    boot.loader.efi.canTouchEfiVariables = cfg.bootloader == "systemd-boot";
    boot.loader.efi.efiSysMountPoint = cfg.bootloaderMountPoint;

    # Ensure we don't have too many old NixOS generations lying around
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.grub.configurationLimit = 10;

    # TODO: Why does uncommenting this line generate an error?
    # This is the main layout I have on my systems. 
    # It works by using the correct labels for drives.
    # boot.initrd.luks.devices."cryptroot".device = (mkIf (cfg.diskLayout == "btrfs-crypt") "/dev/disk/by-label/CRYPTROOT");

    fileSystems."/" = (mkMerge [
      (mkIf (cfg.diskLayout == "btrfs-crypt")
        { device = "/dev/disk/by-label/ROOT";
          fsType = "btrfs";
          options = [ "subvol=@" "discard=async" ];
        }) 
      (mkIf (cfg.diskLayout == "vm")
        {
          device = "/dev/disk/by-label/ROOT";
          fsType = "auto";
          options = [ ];
        })
    ]);

    fileSystems."/home" = (mkIf (cfg.diskLayout == "btrfs-crypt") 
      { device = "/dev/disk/by-label/ROOT";
        fsType = "btrfs";
        options = [ "subvol=@home" "discard=async"  ];
      });

    fileSystems."/var" = (mkIf (cfg.diskLayout == "btrfs-crypt") 
      { device = "/dev/disk/by-label/ROOT";
        fsType = "btrfs";
        options = [ "subvol=@var" "discard=async" ];
      });

    fileSystems."/.pagefile" = (mkIf (cfg.diskLayout == "btrfs-crypt") 
      { device = "/dev/disk/by-label/ROOT";
        fsType = "btrfs";
        options = [ "subvol=@pagefile" "discard=async" ];
      });

    fileSystems."/boot" = (mkIf (cfg.diskLayout == "btrfs-crypt") 
      { device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      });

    swapDevices = (mkIf (cfg.diskLayout == "btrfs-crypt")[  
      {
        device = "/.pagefile/pagefile";
      }
    ]); 
   };
}
