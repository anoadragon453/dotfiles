{pkgs, config, lib, ...}:
with lib;
with pkgs;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiType = config.sys.desktop.gui.type;
  cfg = config.sys;
in {
  config = {

    environment.sessionVariables = mkIf desktopMode {
      # Fix issue with java applications and tiling window managers.
      "_JAVA_AWT_WM_NONREPARENTING" = mkIf (desktopGuiType == "tiling") "1";

      # Enable smooth-scrolling in Mozilla apps
      MOZ_USE_XINPUT2 = "1";
    };

    sys.software = mkIf desktopMode ([
      # These packages are always installed when building a GUI config.

      # Internet
      chromium
      cinny-desktop
      discord
      element-desktop
      mpv
      firefox
      joplin-desktop
      qbittorrent
      signal-desktop
      thunderbird
      tor-browser-bundle-bin

      # Media
      bitwig-studio
      drawpile
      kdenlive
      krita
      mpv
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-backgroundremoval
        ];
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
      gnome.gnome-boxes
      kid3
      vscode
      winetricks
      wineWowPackages.stableFull
      xournalpp
    ] ++ (if (desktopGuiType == "tiling") then [
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
