{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {

  config = mkIf desktopMode {
    programs.steam = {
      # Install Steam gaming platform and set up the runtime environment.
      # Will also implicitly enable hardware.steam-hardware.
      enable = true;

      # Open ports in the firewall for Steam Remote Play
      remotePlay.openFirewall = true;
      # Open ports in the firewall for Source Dedicated Server
      dedicatedServer.openFirewall = true;
    };
  };
}
