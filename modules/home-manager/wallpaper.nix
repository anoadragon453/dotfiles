{ pkgs, ... }:

let
  wallpaperDir = "/home/user/Pictures/wallpapers/";
in {
  # Configure wpaperd, the wallpaper daemon.
  programs.wpaperd = {
    enable = true;
    settings = {
      # For all monitors...
      default = {
        # Source wallpapers from this directory.
        path = wallpaperDir;

        # Each wallpaper wil show for 6 hours.
        duration = "360m";

        # Render a snazzy shadow at the top of the image and under the status bar.
        apply-shadow = true;
      };
    };
  };

  home.packages = [ pkgs.libxkbcommon ];

  # Create a systemd service to run wpaperd on boot.
  systemd.user.services.wpaperd = {
    Unit = {
      Description = "wpaperd - wallpaper daemon";
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wpaperd}/bin/wpaperd";

      # Ensure the wallpaper directory exists such that the unit doesn't fail on start.
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${wallpaperDir}";
    };

    Install = {
      WantedBy = [ "multi-user.target" ];
    };
  };
}