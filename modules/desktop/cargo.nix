{config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {

  config = mkIf desktopMode {
    # Cache build artifacts for all rust projects into a single directory.
    environment.variables = {
      CARGO_HOME = "/home/$USER/.cargo";
      RUSTUP_HOME = "/home/$USER/.rustup";
    };
  };
}
