{ lib, osConfig, ... }:
{
  programs.git = lib.mkIf (builtins.length osConfig.sys.hardware.graphics.desktopProtocols != 0) {
    enable = true;

    # Set the default name and email for commits.
    userEmail = "andrew@amorgan.xyz";
    userName = "Andrew Morgan";

    extraConfig = {
      # Set the default branch name.
      init.defaultBranch = "main";
    };
  };
}