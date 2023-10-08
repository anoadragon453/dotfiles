{pkgs, config, lib, ...}:
let
  cfg = config.sys.hotfix;
in {
  ## This module is a place to put hacks that need to be applied to work around current issues.
  ## You should check back here periodically to see if they can be removed.

  options.sys.hotfix = {};

  config = {
    environment.pathsToLink = ["/libexec" ];

    boot.kernelPatches = [ ];
  };
}
