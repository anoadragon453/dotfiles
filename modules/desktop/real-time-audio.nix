{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  cfg = config.sys.desktop.realTimeAudio;
in {

  options.sys.desktop.realTimeAudio = {

    enable = mkEnableOption "Enable real-time audio support via musnix";

    # Find by running `lspci | grep -i audio` on the system.
    # Example: "00:1b.0"
    soundcardPciId = mkOption {
      type = types.str;
      default = "";
      description = "The PCI ID of the primary soundcard. Used to set the PCI latency timer.";
    };

  };

  config = mkIf desktopMode {
    musnix.enable = cfg.enable;
    musnix.soundcardPciId = cfg.soundcardPciId;
  };

}
