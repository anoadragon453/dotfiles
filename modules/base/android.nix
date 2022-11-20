{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
  config = {
    # Enable android device bridge support
    programs.adb.enable = true;

    sys.software = [
      # adb, fastboot and other android cli tools
      android-tools
    ];

  };

}
