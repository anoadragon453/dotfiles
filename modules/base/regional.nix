{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
  options.sys = {
    locale = mkOption {
      type = types.str;
      description = "The locale for the machine";
      default = "en_GB.UTF-8";
    };

    timeZone = mkOption {
      type = types.str;
      description = "The timezone of the machine";
      default = "Europe/London";
    };
  };

  config = {
    i18n.defaultLocale = cfg.locale;
    time.timeZone = cfg.timeZone;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.locale;
      LC_IDENTIFICATION = cfg.locale;
      LC_MEASUREMENT = cfg.locale;
      LC_MONETARY = cfg.locale;
      LC_NAME = cfg.locale;
      LC_NUMERIC = cfg.locale;
      LC_PAPER = cfg.locale;
      LC_TELEPHONE = cfg.locale;
      LC_TIME = cfg.locale;
    };
  };
}
