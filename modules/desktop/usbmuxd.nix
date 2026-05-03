{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in
{
  config = mkIf desktopMode {
    sys.software = with pkgs; [
      libimobiledevice
      libimobiledevice-glue

      # For connecting an iOS device to a dockerized MacOS.
      usbfluxd
    ];

    # For tethering from iPhones.
    services.usbmuxd.enable = true;
  };
}
