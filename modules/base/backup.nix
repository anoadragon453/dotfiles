{config, lib, pkgs, ...}:
let
  cfg = config.sys.backup;

  # A common set of paths to exclude from backups.
  excludedPaths = [
    # Temporary files that end in ~.
    "*~"

    # Cache directories
    "/home/*/.cache/**"
    "/home/*/.config/**/Cache"

    # NixOS VM images
    "dotfiles/*.qcow2"

    # Mounted files.
    "/run/media"
    "/mnt"

    # Rust build directories.
    "target/release"
    "target/debug"

    # Git folders contain millions of files, and they can be rebuilt.
    ".git"

    # Any node module directories.
    "node_modules"

    # Compiled language files.
    "*.pyc"
    "*.o"
    "*.lo"
  ];
in {
  options.sys.backup = {
    restic = {
      enable = lib.mkEnableOption "Enable the restic backup service";

      backupPasswordFileSecret = lib.mkOption {
        type = lib.types.str;
        description = "The sops secret pointing to a file containing the restic backup password";
      };

      repository = lib.mkOption {
        type = lib.types.str;
        description = "The location of the restic repository";
      };

      includedPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "/home" ];
        description = "A list of paths to include from the backup";
      };

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "A list of extra cli flags to pass to 'restic'";
      };

      extraExcludedPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "A list of paths to exclude from the backup in addition to the default set";
      };
    };
  };

  config = {
    services.restic.backups."remote-backup" = lib.mkIf cfg.restic.enable {
      # The remote host containing the restic repository.
      repository = cfg.restic.repository;

      # The paths to backup.
      paths = cfg.restic.includedPaths;

      # The paths to exclude from the backup.
      exclude = excludedPaths ++ cfg.restic.extraExcludedPaths;

      # The path to a file containing the repository encryption password.
      passwordFile = config.sops.secrets."${cfg.restic.backupPasswordFileSecret}".path;

      # Any extra options.
      extraOptions = cfg.restic.extraOptions;

      # When the backup will run.
      timerConfig = {
        # Back up daily.
        OnCalendar = "daily";

        # If the computer was asleep/off when a backup should have been performed
        # (and thus the backup was issed), run the backup once it comes on.
        #
        # TODO: This seems to attempt to run right as the computer switches on, which
        # doesn't work as network isn't initialised yet. Can we retry, with some delay?
        Persistent = true;

        # Randomly delay backing up in order to prevent all machines in the same timezone
        # from backing up at the same time (putting high load on the server).
        RandomizedDelaySec = "3h";
      };

      # Options
      #   * --verbose: Log a minimal amount to aid debugging.
      #   * --no-scan: Do not scan entire filesystem before backing up (saves ~1min)
      extraBackupArgs = [ "--verbose" "--no-scan" ];
    };

    # Wait for 30s before backing up, as internet may not have connected yet.
    # Typically this bit would be handled by waiting for nm-online.target, but we disable that service...
    systemd.services.restic-backups-remote-backup.serviceConfig.ExecStartPre = [ "${pkgs.coreutils}/bin/sleep 30" ];
  };
}