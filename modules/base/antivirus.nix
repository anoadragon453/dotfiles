{pkgs, config, lib, ...}:
with lib;
let
  cfg = config.sys.security.antivirus;
  quarantineDirectory = "/var/lib/clamav/quarantine";
  # A script that will run upon a virus being detected on access.
  onVirusEvent = pkgs.writeTextFile {
    name = "virus-event.sh";
    text = ''
      ALERT="Signature detected by clamav: '$CLAM_VIRUSEVENT_VIRUSNAME' in '$CLAM_VIRUSEVENT_FILENAME'"

      # Send an alert to all graphical users.
      for ADDRESS in /run/user/* ; do
        # Extract the '1001' from '/run/user/1001'.
        USERID=$(echo $ADDRESS | ${pkgs.coreutils}/bin/cut -c 11-)
        USERNAME=$(${pkgs.getent}/bin/getent passwd "$USERID" | ${pkgs.coreutils}/bin/cut -d: -f1)
        echo "USERID is $USERID"
        echo "USERNAME is $USERNAME"
        /run/wrappers/bin/sudo -u "$USERNAME" DBUS_SESSION_BUS_ADDRESS="unix:path=$ADDRESS/bus" \
          ${pkgs.libnotify}/bin/notify-send -i dialog-warning -a clamav "Malware found!" "$ALERT"
      done
    '';
    executable = true;
    destination = "/bin/virus-event.sh";
  };
in {
  options.sys.security.antivirus = {
    clamav.enable = mkEnableOption "ClamAV antivirus";
    clamav.pathsToExcludeRegex = mkOption {
      type = types.str;
      description = "A regex defining the path(s) to exclude from anti-virus scanning";
      default = ""; 
    };
    clamav.pathToIncludeOnAccess = mkOption {
      type = types.str;
      description = "A filepath that defines which files ClamAV will scan on an access attempt.";
      default = ""; 
    };
    clamav.runCommandOnVirusFound = mkOption {
      type = types.str;
      description = ''
        A command to run if a virus is found. Use %v as a placeholder for the path to the offending file.
        Additionally,  two environment variables are defined: $CLAM_VIRUSEVENT_FILENAME and
        $CLAM_VIRUSEVENT_VIRUSNAME.
        '';
      default = "";
    };
    clamav.clamOnAcc.quarantineEnabled = mkEnableOption "moving files detected as viruses to a quarantine directory (${quarantineDirectory})";
  };

  config = {
    # The ClamAV anti-virus daemon.
    # TODO: The first time the clamav-daemon system service is started, it will fail. The
    #   clamav-freshclam service needs to run first (to download virus definitions).
    services.clamav.daemon.enable = cfg.clamav.enable;

    # Install notify-send in order to notify the user that file access was denied due to
    # virus detection.
    sys.software = (mkIf cfg.clamav.enable (with pkgs; [libnotify]));

    # A script to execute upon virus detection.
    environment.etc."clamav/virus-event.sh".source = (mkIf cfg.clamav.enable onVirusEvent);

    # A systemd service to run clamonacc - the OnAccess file scanning daemon.
    systemd.services.clamav-clamonacc = mkIf cfg.clamav.enable {
      description = "ClamAV virus file access scanner (clamonacc) ";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p ${quarantineDirectory}
        chown clamav:clamav ${quarantineDirectory}
      '';

      serviceConfig = {
        ExecStart = "${pkgs.clamav}/bin/clamonacc -F --fdpass --move=${quarantineDirectory}";
        SuccessExitStatus = "1";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
      };
    };

    # Settings for the daemon.
    # See `man clamd.conf` for all settings.
    services.clamav.daemon.settings = {
      # Log to the syslog.
      LogSyslog = true;

      ExcludePath = cfg.clamav.pathsToExcludeRegex;

      # TODO: I attempted to send a notification to all users when a virus was found, but this proved
      # difficult, as I cannot figure out how to let the 'clamav' user use 'sudo'.
      # See https://github.com/NixOS/nixpkgs/issues/42117.
      #VirusEvent = "${onVirusEvent}/bin/virus-event.sh";

      # On-Access Scanning
      # Settings pertaining to virus scanning on file access.

      # Prevent access to files which are considered to contain viruses.
      OnAccessPrevention = true;

      # Perform a scan when a directory within the configured scanning directory is created or moved.
      OnAccessExtraScanning = true;

      # The path to scan files for viruses on access.
      # TODO: These can be a list of string apparently.
      OnAccessIncludePath = (mkIf (cfg.clamav.pathToIncludeOnAccess != "") cfg.clamav.pathToIncludeOnAccess);

      # Maximum size of files to scan when attempting to access them.
      OnAccessMaxFileSize = "20M";

      # Allow the clamav user to access files without virus scanning.
      OnAccessExcludeUname = "clamav";

      # General Scanning Settings
      ScanMail = true;
      ScanPDF = true;
      ScanHTML = true;

      MaxScanSize = "100M";
      MaxFileSize = "25M";

      # Maximum number of recursion levels when scanning nested archives.
      MaxRecursion = 16;

      # Number of files to be scanned within an archive, a document, or any other kind of container.
      MaxFiles = 10000;

      # Don't scan directories and files on other filesystems.
      CrossFilesystems = false;
    };

    # The updater for virus definitions.
    # The default update frequency is "hourly" with a maximum
    # of 12 updates per day.
    services.clamav.updater.enable = cfg.clamav.enable;
  };
}
