{ ... }:
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
  };
}