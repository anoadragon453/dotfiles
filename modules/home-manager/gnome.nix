{ lib, osConfig, ... }:
{
  # Set dconf settings.
  #
  # Hint: use `dconf watch /` in a terminal and flip an option to find
  # out what its path/value is.
  dconf.settings = lib.mkIf (lib.elem "gnome" osConfig.sys.desktop.gui.types) {
    # Set the "Additional Layout Options" from GNOME Tweaks.
    #   * caps:none -> Disable caps lock.
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:none" ];
    };

    # Enable user extensions.
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "advanced-alt-tab@G-dH.github.com"
        "alt-tab-scroll-workaround@lucasresck.github.io"
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        "fullscreen-notifications@sorrow.about.alice.pm.me"
        "gsconnect@andyholmes.github.io"
        "hass-gshell@geoph9-on-github"
        "hibernate-status@dromi"
        "steal-my-focus-window@steal-my-focus-window"
        "trayIconsReloaded@selfmade.pl"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
      disabled-extensions = [];
    };

    # Snap windows to edges of display.
    "org/gnome/mutter" = {
      edge-tiling = true;
    };

    "org/gnome/desktop/interface" = {
      # Use the dark theme.
      color-scheme = "prefer-dark";

      # Show seconds in the clock.
      clock-show-seconds = true;
    };

    # Turn off lock-screen notifications.
    # These will wake up the monitor when the computer is asleep,
    # which wastes power.
    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
    };

    # Set the screen blank timeout to 15 minutes.
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 900;
    };

    # Don't automatically suspend the computer.
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };

    # Remove unused services from GNOME's global search.
    "org/gnome/desktop/search-providers" = {
      enabled = [];
      disabled = ["org.gnome.Nautilus.desktop" "org.gnome.Characters.desktop" "org.gnome.clocks.desktop" "org.gnome.Software.desktop"];
    };

    # Keybindings for built-in actions.
    "org/gnome/desktop/wm/keybindings" = {
      # Close windows via Alt-Shift-Q.
      close = [ "<Shift><Alt>q" ];

      # Take a screenshot with Alt-Shift-S.
      show-screenshot-ui = [ "<Shift><Alt>s" ];
    };

    # Keybindings for custom commands.

    # Open the terminal with Alt-Enter.
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Open Terminal";
      binding = "<Alt>Return";
      command = "alacritty";
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
    };

    # I was seeing errors about this key being missing, and this appeared to be
    # linked to gdm crashing... so I've added it with a random shortcut sequence.
    "org/gnome/shell/keybindings" = {
      open-application-menu = ["<Alt>g"];
    };

    # Set the GTK theme.
    # We use the theme installed via gtk.nix.
    "org/gnome/shell/extensions/user-theme" = {
      name = "WhiteSur-Dark";
    };
  };
}