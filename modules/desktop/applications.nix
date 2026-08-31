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

  obsidian = pkgs.obsidian.overrideAttrs (previous: {
    # Fix the desktop icon for Obsidian being the default Wayland icon.
    postInstall = (previous.postInstall or "") + ''
      # KWin resolves native Wayland windows using this desktop file ID.
      mv $out/share/applications/obsidian.desktop \
        $out/share/applications/md.Obsidian.desktop
    '';
  });
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
      vintagestory

      # Media
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
      appimage-run
      ascii
      bubblewrap # for sandboxing AI agent commands
      pkgsUnstable.codex
      contrast
      freecad
      git-absorb
      gnome-disk-utility
      gramps
      nh
      nil # for vscode 'nil' extension
      notify-desktop # for having codex-cli send desktop notifications
      poppler-utils # includes pdfunite
      shellcheck
      solaar
      translatelocally
      virt-manager
      vscode
      # wineWowPackages.stableFull
      xournalpp

      # Work
      android-studio
      pkgsUnstable.zizmor
      sops
      mitmproxy

      # K8s/Helm
      k9s
      k3d
      chart-testing
      kubeconform
      envchain
      skopeo
      kubectl
      kubelogin
      kubelogin-oidc
      kubectx
      yq-go
      (wrapHelm kubernetes-helm {
        plugins = with pkgs.kubernetes-helmPlugins; [
          helm-secrets
          helm-diff
          helm-s3
          helm-git
        ];
      }) 
      helmfile-wrapped
      kind
      vault
    ];
  };
}
