{config, lib, ...}:
with lib;
with builtins;
let
  cfg = config.sys;
in {

  imports = [ 
    ./scripts.nix 
  ];

  options.sys = {
    software = mkOption {
      type = with types; listOf package;
      description = "List of software to install";
      default = [];
    };
  };

  config = {
    environment.systemPackages = cfg.software;
  };
}
