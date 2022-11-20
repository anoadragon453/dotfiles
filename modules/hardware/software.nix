{pkgs, config, lib, ...}:
{
    # Software package
    sys.software = with pkgs; [
        acpi
        btrfs-progs
        dmidecode
        exfat
        hwdata
        iotop
        lm_sensors
        ntfsprogs
        nvme-cli
        pciutils
        smartmontools
        usbutils
    ];

}
