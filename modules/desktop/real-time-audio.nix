{config, lib, pkgs, ...}:
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

    # Use real-time kernel for audio production.
    # We set this instead of the musnix.kernel.realtime option, as that will
    # trigger a rebuild of the kernel (which significantly slows down system updates.)
    # Use lib.mkDefault to allow this to be overridden per-machine in flake.nix.
    sys.kernelPackage = lib.mkDefault pkgs.linuxPackages-rt_latest;
  };

}
