{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  config = mkIf desktopMode {

    sys.software = with pkgs; [
      breeze-gtk
    ];

    # TODO: Leave for now. Do we care about anything here?
    sys.user.allUsers.files = {
      gtkSettings3 = {
        path = ".config/gtk-3.0/settings.ini";
        text = ''
          [Settings]
          gtk-button-images=1
          gtk-cursor-theme-name=Adwaita
          gtk-cursor-theme-size=0
          gtk-enable-event-sounds=1
          gtk-enable-input-feedback-sounds=1
          gtk-font-name=Cantarell 11
          gtk-icon-theme-name=Adwaita
          gtk-menu-images=1
          gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
          gtk-toolbar-style=GTK_TOOLBAR_BOTH
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintfull
        '';
      };

      # gtkSettings4 = {
      #   path = ".config/gtk-4.0/settings.ini";
      #   text = ''
      #     [Settings]
      #   '';
      # };

    };
  };
}
