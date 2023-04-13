{pkgs, config, lib, ...}:
with lib;
let
  cfg = config.sys.security.antivirus;
  quarantineDirectory = "/var/lib/clamav/quarantine";
in {
  options.sys.security.antivirus = {
    clamav.enable = mkEnableOption "ClamAV antivirus";
    clamav.pathsToExcludeRegex = mkOption {
      type = types.listOf types.str;
      description = ''
        A list of regular expressions defining the path(s) to exclude from anti-virus scanning
      '';
      default = []; 
    };
    clamav.pathsToIncludeOnAccess = mkOption {
      type = types.listOf types.str;
      description = ''
        Filepaths that define that directories containing files which ClamAV will scan
        upon attempting to access said file, or moving a file in or out of.
      '';
      default = []; 
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

    # A systemd service to run clamonacc - the OnAccess file scanning daemon.
    systemd.services.clamav-clamonacc = mkIf ((length cfg.clamav.pathsToIncludeOnAccess) != 0) {
      description = "ClamAV virus file access scanner (clamonacc) ";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p ${quarantineDirectory}
        chown clamav:clamav ${quarantineDirectory}
      '';

      # Don't start the on-access scanner until the ClamAV daemon itself has started. Similarly,
      # stop the on-access scanner if the daemon service stops.
      requires = [ "clamav-daemon.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.clamav}/bin/clamonacc --config-file /etc/clamav/clamd.conf -F --fdpass --move=${quarantineDirectory}";
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

      VirusEvent = (mkIf (cfg.clamav.runCommandOnVirusFound != "") cfg.clamav.runCommandOnVirusFound);

      # On-Access Scanning
      # Settings pertaining to virus scanning on file access.

      # Prevent access to files which are considered to contain viruses.
      OnAccessPrevention = (length cfg.clamav.pathsToIncludeOnAccess) != 0;

      # Perform a scan when a directory within the configured scanning directory is created or moved.
      OnAccessExtraScanning = (length cfg.clamav.pathsToIncludeOnAccess) != 0;

      # The path to scan files for viruses on access.
      OnAccessIncludePath = cfg.clamav.pathsToIncludeOnAccess;

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
