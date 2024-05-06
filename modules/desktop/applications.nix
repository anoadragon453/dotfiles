{pkgs, config, lib, ...}:
let
  xorg = (builtins.elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (builtins.elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiTypes = config.sys.desktop.gui.types;
  cfg = config.sys;
in {
  config = lib.mkIf desktopMode {

    environment.sessionVariables = {
      # Fix issue with java applications and tiling window managers.
      "_JAVA_AWT_WM_NONREPARENTING" = lib.mkIf (builtins.elem "tiling" desktopGuiTypes) "1";

      # Enable smooth-scrolling in Mozilla apps
      MOZ_USE_XINPUT2 = "1";
    };

    sys.software = with pkgs; ([
      # These packages are always installed when building a GUI config.

      # Internet
      anydesk
      chromium
      discord
      mpv
      filezilla
      joplin-desktop
      qbittorrent
      nextcloud-client
      rustdesk-flutter
      signal-desktop
      telegram-desktop
      tor-browser-bundle-bin
      warp
      # thunderbird is installed via thunderbird.nix

      # Audio production
      bitwig-studio

      # Office
      obsidian
      onlyoffice-bin

      # Games
      airshipper # launcher and updater for veloren
      minecraft

      # Media
      drawpile
      easyeffects
      inkscape
      kdenlive
      krita
      mpv
      obs-studio
      pavucontrol
      picard
      qpwgraph
      yabridge
      yabridgectl
      vlc
      (if (
        # blender-hip sets up AMD HIP rendering for Blender.
        # Only install blender-hip if we have an amd card.
        cfg.hardware.graphics.primaryGPU == "amd" || cfg.hardware.graphics.extraGPU == "amd"
      ) then blender-hip else blender)

      # Tools
      android-studio
      appimage-run
      ascii
      contrast
      gnome.gnome-boxes
      jetbrains.pycharm-community
      kid3
      poppler_utils  # includes pdfunite
      solaar
      winetricks
      wineWowPackages.stableFull
      wireshark
      xournalpp
    ] ++ (if (builtins.elem "tiling" desktopGuiTypes) then [
      # Only installed when using a tiling window manager.
      feh
      libsixel
      maim
      pkgs.xorg.xev
      pkgs.xorg.xhost
      pkgs.xorg.xmodmap
      xclip
      xdg-desktop-portal-wlr
    ] else [])
    );
  };
}
