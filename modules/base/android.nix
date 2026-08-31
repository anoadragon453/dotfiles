{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
  config = {
    sys.software = [
      # adb, fastboot and other android cli tools
      android-tools
    ];

  };

}
