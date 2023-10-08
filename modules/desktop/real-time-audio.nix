{config, lib, pkgs, ...}:
let
  cfg = config.sys.desktop.realTimeAudio;
in {

  # This module is enabled simply by importing it in your system's config.
  # It is not imported by default (it's not in ./default.nix).
  options.sys.desktop.realTimeAudio = {
    # Find by running `lspci | grep -i audio` on the system.
    # Example: "00:1b.0"
    soundcardPciId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The PCI ID of the primary soundcard. Used to set the PCI latency timer.";
    };
  };

  config = {
    musnix.enable = true;
    musnix.soundcardPciId = cfg.soundcardPciId;

    # Use real-time kernel for audio production.
    # We set this instead of the musnix.kernel.realtime option, as that will
    # trigger a rebuild of the kernel (which significantly slows down system updates.)
    # Use lib.mkDefault to allow this to be overridden per-machine in flake.nix.
    sys.kernelPackage = lib.mkDefault pkgs.linuxPackages-rt_latest;
  };

}
