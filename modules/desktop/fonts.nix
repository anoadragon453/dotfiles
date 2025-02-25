{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  
  config = mkIf desktopMode {
    # This is *all* nerd-fonts.
    # TODO: Separate out the fonts we actually need.
    fonts.packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    sys.user.allUsers.files = {
      fontconf = {
        path = ".config/fontconfig/fonts.conf";
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias>
              <family>monospace</family>
              <prefer>
                <family>Monoid Nerd Font Mono</family>
              </prefer>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
