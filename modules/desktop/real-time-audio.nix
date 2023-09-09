{config, lib, ...}:
with lib;
with builtins;
let
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

  config = mkIf cfg.enable {
    musnix.enable = cfg.enable;
    musnix.soundcardPciId = cfg.soundcardPciId;
  };

}
