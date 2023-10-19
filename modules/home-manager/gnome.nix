{ lib, ... }:
{
  # Set dconf settings.
  #
  # Hint: use `dconf watch /` in a terminal and flip an option to find
  # out what its path/value is.
  dconf.settings = {
    # Set the "Additional Layout Options" from GNOME Tweaks.
    #   * caps:none -> Disable caps lock.
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:none" ];
    };

    # Enable user extensions.
    "org/gnome/shell" = {
      disable-user-extensions = false;
    };

    # Snap windows to edges of display.
    "org/gnome/mutter" = {
      edge-tiling = true;
    };

    # Use the dark theme.
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
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
    };

    # Keybindings
    "org/gnome/desktop/wm/keybindings" = {
      # Close windows via Alt-Shift-Q.
      close = [ "<Shift><Alt>q" ];

      # Take a screenshot with Alt-Shift-S.
      show-screenshot-ui = [ "<Shift><Alt>s" ];
    };
  };
}