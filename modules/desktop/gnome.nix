{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
let

  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  desktopGuiTypes = config.sys.desktop.gui.types;
  desktopMode = wayland || xorg;

  cfg = config.sys.desktop.gui.gnome;
in {
  options.sys.desktop.gui.gnome = {
    commonExtensions = mkOption {
      description = "List of common GNOME extensions that most installations will need";
      type = types.listOf types.package;
      default = with gnomeExtensions; [
        advanced-alttab-window-switcher
        alttab-scroll-workaround
        caffeine
        fullscreen-notifications
        hibernate-status-button
        home-assistant-extension
        tray-icons-reloaded
      ];
    };

    extraExtensions = mkOption {
      description = "List of additional GNOME extensions to install that are computer-specific";
      type = types.listOf types.package;
      default = [];
    };

    extraConfig = mkOption {
      description = "Extra config to apply to GNOME";
      type = types.lines;
      default = "";
    };
  };


  config = mkIf (desktopMode && elem "gnome" desktopGuiTypes) {
    # Install and configure GNOME
    services.xserver.desktopManager.gnome.enable = true;
    
    # Work around GDM not starting GNOME in Wayland mode by default.
    # From https://discourse.nixos.org/t/fix-gdm-does-not-start-gnome-wayland-even-if-it-is-selected-by-default-starts-x11-instead/24498
    services.xserver.displayManager.defaultSession = "gnome";

    # Install some helpful packages when using GNOME
    sys.software = (with pkgs; [
      gnome.gnome-tweaks  # Additional configuration options for GNOME.
    ]) ++ cfg.commonExtensions ++ cfg.extraExtensions;

    # Exclude some default GNOME packages from being installed
    # Full list: https://github.com/NixOS/nixpkgs/blob/release-22.05/nixos/modules/services/x11/desktop-managers/gnome.nix#L483
    environment.gnome.excludePackages = [
      gnome-photos
      gnome-tour
    ] ++ (with gnome; [
      atomix    # puzzle game
      epiphany  # web browser
      geary     # email reader
      hitori    # sudoku game
      iagno     # go game
      tali      # poker games
      totem     # gnome videos
    ]);

  };

}
