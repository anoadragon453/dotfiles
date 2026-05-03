{
  pkgs,
  config,
  lib,
  pkgsUnstable,
  ...
}:
let
  xorg = (builtins.elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (builtins.elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  desktopGuiTypes = config.sys.desktop.gui.types;
  cfg = config.sys;
in
{
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
      parsec-bin
      qbittorrent
      signal-desktop
      telegram-desktop
      tor-browser
      thunderbird

      # Office
      obsidian
      onlyoffice-desktopeditors
      tectonic
      gnome-text-editor # for quick note-taking, useful as it restores unsaved documents

      # Games
      prismlauncher

      # Media
      audacity
      inkscape
      kdePackages.kdenlive
      krita
      losslesscut-bin
      mpv
      obs-studio
      pavucontrol
      qpwgraph
      (
        if
          (
            # blender-hip sets up AMD HIP rendering for Blender.
            # Only install blender-hip if we have an amd card.
            cfg.hardware.graphics.primaryGPU == "amd" || cfg.hardware.graphics.extraGPU == "amd"
          )
        then
          blender-hip
        else
          blender
      )

      # Tools
      android-studio
      appimage-run
      ascii
      pkgsUnstable.codex
      contrast
      freecad
      git-absorb
      gnome-disk-utility
      nh
      notify-desktop # for having codex-cli send desktop notifications
      poppler-utils # includes pdfunite
      solaar
      translatelocally
      virt-manager
      vscode
      wineWowPackages.stableFull
      pkgsUnstable.zizmor
    ];
  };
}
