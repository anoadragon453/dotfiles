{pkgs, config, lib, pkgsUnstable, ...}:
let
  xorg = (builtins.elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (builtins.elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiTypes = config.sys.desktop.gui.types;
  cfg = config.sys;
in {
  config = lib.mkIf desktopMode {

    environment.sessionVariables = {
      # Enable smooth-scrolling in Mozilla apps
      MOZ_USE_XINPUT2 = "1";
    };

    sys.software = with pkgs; [
      # These packages are always installed when building a GUI config.

      # Internet
      chromium
      discord
      mpv
      filezilla
      qbittorrent
      signal-desktop
      telegram-desktop
      tor-browser-bundle-bin
      # thunderbird is installed via thunderbird.nix

      # Office
      obsidian
      onlyoffice-bin
      prusa-slicer

      # Games
      prismlauncher

      # Media
      inkscape
      kdePackages.kdenlive
      krita
      mpv
      obs-studio
      pavucontrol
      qpwgraph
      stremio
      (if (
        # blender-hip sets up AMD HIP rendering for Blender.
        # Only install blender-hip if we have an amd card.
        cfg.hardware.graphics.primaryGPU == "amd" || cfg.hardware.graphics.extraGPU == "amd"
      ) then blender-hip else blender)

      # Tools
      appimage-run
      ascii
      contrast
      freecad
      nh
      poppler_utils  # includes pdfunite
      solaar
      translatelocally
      virt-manager
      wineWowPackages.stableFull
    ];
  };
}
