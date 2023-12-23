{pkgs, config, lib, ...}:
with lib;
let
  wrappedThunderbird = pkgs.stdenv.mkDerivation {
    name = "thunderbird";

    buildInputs = with pkgs; [ makeWrapper ];

    desktopItem = pkgs.makeDesktopItem ({
        name = "Thunderbird";
        exec = "thunderbird --name Thunderbird %U";
        icon = "thunderbird";
        desktopName = "Thunderbird";
        startupNotify = true;
        terminal = false;
    });

    buildCommand = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.thunderbird}/bin/thunderbird $out/bin/thunderbird \
        --set TEMP "${cfg.customTempDirectory}"
      install -D -t $out/share/icons $desktopItem/share/icons/*
      install -D -t $out/share/applications $desktopItem/share/applications/*
    '';
  };
  cfg = config.sys.thunderbird;
in {
  options.sys.thunderbird = {
    customTempDirectory = mkOption {
      type = types.str;
      description = ''
        Set a custom temporary directory for Thunderbird to use, i.e. where email
        attachments are stored upon opening them. If this is not set, Thunderbird
        will use /tmp.
      '';
      default = "";
    };
  };

  config = {
    # Install thunderbird.
    # If a custom temp directory is specified, install our wrapper around the thunderbird
    # package instead of the vanilla package.
    sys.software = if cfg.customTempDirectory != "" then [ wrappedThunderbird ] else [ pkgs.thunderbird ];

    # Create the /tmp/thunderbird directory - which our wrappedThunderbird package relies
    # on - with the correct permissions.
    systemd.tmpfiles.rules = mkIf (cfg.customTempDirectory != "") [
      "d /tmp/thunderbird 0777 root root"
    ];
  };
}