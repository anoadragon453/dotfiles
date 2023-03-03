{pkgs, lib, config, home-manager, ...}:
with pkgs;
with lib;
with builtins;
let

  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  desktopGuiType = config.sys.desktop.gui.type;
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


  config = mkIf (desktopMode && desktopGuiType == "gnome") {
    # Install and configure GNOME
    services.xserver.desktopManager.gnome.enable = true;

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

    # TODO: Figure out some way to detect the user.
    # Maybe via https://github.com/hlissner/dotfiles/blob/089f1a9da9018df9e5fc200c2d7bef70f4546026/modules/options.nix#L39-L43?
    # Even though that seems like a hack...
    #home-manager.users.${builtins.getEnv "USER"}.programs.xmobar.enable = true;
    # TODO: New idea, rewrite the user module stuff to use home-manager instead. Would use
    # home manager to create the files and things in the home directory.
    # And then in different modules - like this one - we'd set options on a dummy set like
    # hm.programs.xmobar.enable = true; and then the user module would run all of those for
    # each configured user!
    home-manager.users.user.programs.xmobar.enable = true;

    # TODO: Put this in a home-manager nix module
    home-manager.users.user.home.stateVersion = config.system.stateVersion;
  };

}
