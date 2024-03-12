{ config, ... }:
{
  # Consolidate all rust build files into a single directory on disk, to prevent
  # duplicate built dependencies across different projects.
  xdg.configFile = { 
    "cargo/config.toml" = {
      enable = true;
      text = ''
        [build]
        target-dir = "${config.xdg.configHome}/.cargo/target"
      '';
    };
  };
}