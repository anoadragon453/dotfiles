{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
let
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  desktopGuiTypes = config.sys.desktop.gui.types;
  desktopMode = wayland || xorg;

  cfg = config.sys.desktop.gui.kde;
in {
  options.sys.desktop.gui.kde = {};


  config = mkIf (desktopMode && elem "kde" desktopGuiTypes) {
    # Install and configure KDE Plasma5
    services.xserver.desktopManager.plasma5.enable = true;

    # Enable HiDPI scaling in Qt applications.
    services.xserver.desktopManager.plasma5.useQtScaling = true;

    # Fix GTK themes not applying in Wayland applications.
    # From https://nixos.wiki/wiki/KDE
    programs.dconf.enable = true;

    # Install some helpful packages when using KDE
    # TODO:

    # ksshaskpass conflicts with SeaHorse's askpass implementation when GNOME and KDE are both enabled.
    programs.ssh.askPassword = mkIf (elem "gnome" desktopGuiTypes) (mkForce "${pkgs.libsForQt5.ksshaskpass}");

    # Exclude some default KDE apps from being installed
    # Full list: https://github.com/NixOS/nixpkgs/blob/release-22.05/nixos/modules/services/x11/desktop-managers/gnome.nix#L483
    # services.xserver.desktopManager.plasma5.excludePackages = with pkgs.libsForQt5; [
    # ];

  };

}
