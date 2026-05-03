{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
  cfg = config.sys;
in {
    config = {
        # Enable all unfree hardware support.
        hardware.firmware = with pkgs; [ linux-firmware ];
        hardware.enableAllFirmware = true;
        hardware.enableRedistributableFirmware = true;

        # Enable firmware update service
        services.fwupd.enable = true;
    };
}
