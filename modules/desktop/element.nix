{pkgs, lib, config, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  config = (mkIf desktopMode) {
    # Install Element desktop stable.
    sys.software = with pkgs; [
      element-desktop
    ];

    # Configure Element Desktop settings.
    # Documentation: https://github.com/vector-im/element-web/blob/develop/docs/config.md
    #
    # The default config file can be found here:
    # https://github.com/vector-im/element-web/blob/develop/config.sample.json
    sys.user.allUsers.files = {
      elementcfg = {
        path = ".config/Element/config.json";
        text = ''
        {
          "default_server_config": {
              "m.homeserver": {
                  "base_url": "https://matrix.amorgan.xyz",
                  "server_name": "amorgan.xyz"
              },
              "m.identity_server": {
                  "base_url": "https://vector.im"
              }
          },
          "disable_custom_urls": false,
          "disable_guests": false,
          "disable_login_language_selector": false,
          "disable_3pid_login": false,
          "brand": "Element",
          "integrations_ui_url": "https://scalar.vector.im/",
          "integrations_rest_url": "https://scalar.vector.im/api",
          "integrations_widgets_urls": [
              "https://scalar.vector.im/_matrix/integrations/v1",
              "https://scalar.vector.im/api",
              "https://scalar-staging.vector.im/_matrix/integrations/v1",
              "https://scalar-staging.vector.im/api",
              "https://scalar-staging.riot.im/scalar/api"
          ],
          "bug_report_endpoint_url": "https://element.io/bugreports/submit",
          "uisi_autorageshake_app": "element-auto-uisi",
          "default_country_code": "GB",
          "show_labs_settings": true,
          "features": {},
          "default_federate": true,
          "default_theme": "light",
          "room_directory": {
              "servers": ["matrix.org", "amorgan.xyz", "mozilla.org", "kde.org", "gnome.org"]
          },
          "enable_presence_by_hs_url": {
              "https://matrix.org": false,
              "https://matrix-client.matrix.org": false,
              "https://amorgan.xyz": false,
              "https://matrix.amorgan.xyz": false
          },
          "setting_defaults": {
              "breadcrumbs": true
          },
          "jitsi": {
              "preferred_domain": "meet.element.io"
          },
          "element_call": {
              "url": "https://call.element.io",
              "participant_limit": 8,
              "brand": "Element Call"
          },
          "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
        }
        '';
      };
    };
  };
}
