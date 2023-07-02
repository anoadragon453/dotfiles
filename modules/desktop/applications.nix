{pkgs, config, lib, ...}:
with lib;
with pkgs;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiTypes = config.sys.desktop.gui.types;
  cfg = config.sys;
in {
  config = {

    environment.sessionVariables = mkIf desktopMode {
      # Fix issue with java applications and tiling window managers.
      "_JAVA_AWT_WM_NONREPARENTING" = mkIf (elem "tiling" desktopGuiTypes) "1";

      # Enable smooth-scrolling in Mozilla apps
      MOZ_USE_XINPUT2 = "1";
    };

    sys.software = mkIf desktopMode ([
      # These packages are always installed when building a GUI config.

      # Internet
      anydesk
      chromium
      discord
      mpv
      firefox
      joplin-desktop
      qbittorrent
      signal-desktop
      # thunderbird is installed via thunderbird.nix

      # Audio production
      bitwig-studio

      # Office
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
      (wrapOBS {
        plugins = with obs-studio-plugins; [ ];
      })
      pavucontrol
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
      gnome.gnome-boxes
      jetbrains.pycharm-community
      kid3
      solaar
      winetricks
      wineWowPackages.stableFull
      wireshark
      xournalpp
    ] ++ (if (elem "tiling" desktopGuiTypes) then [
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
