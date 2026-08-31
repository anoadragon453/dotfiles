{ config, ... }:
{
  # Consolidate all rust build files into a single directory on disk, to prevent
  # duplicate built dependencies across different projects.
  programs.cargo = {
    enable = true;
    # Let devenv install cargo instead.
    package = null;
    settings = { 
      build = {
        target-dir = "${config.home.homeDirectory}/.cargo/target";
      };
      unstable = {
        unstable-options = true;

        # Unify all feature flags across the workspace.
        feature-unification = true;

        # Enable garbage collection of the target directory.
        gc = true;
      };
    };
  };
}