{ lib, osConfig, ... }:
{
  programs.firefox = lib.mkIf (builtins.length osConfig.sys.hardware.graphics.desktopProtocols != 0) {
    # Install and manage firefox via home-manager.
    enable = true;

    profiles."home-manager" = {
      userChrome = ''
        /* Hide tab bar in FF Quantum */
        #TabsToolbar {
          visibility: collapse !important;
          margin-bottom: 21px !important;
        }

        /* Hide Firefox's general sidebar header */
        #sidebar-header {
          visibility: collapse !important; 
        }

        #sidebar-splitter {
          /* Recolor the sidebar splitter bar to the same as the bg color. */
          background-color: var(--toolbar-field-background-color) !important;

          /* Remove the border. */
          border: unset !important;
        }
      '';

      # Tell Firefox to use userChrome.css customisations.
      extraConfig = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
      '';
    };
  };
}