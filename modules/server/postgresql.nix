{ config, lib, ... }:

let
  cfg = config.sys.server.postgresql.backups;
in {
  options.sys.server.postgresql.backups = {
    enable = lib.mkEnableOption "Enable system-wide postgres backups";

    backupLocationFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The directory to store PostgreSQL dumps under";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresqlBackup = {
      enable = true;
      backupAll = true;
      compression = "zstd";
      location = cfg.backupLocationFilePath;
    };
  };
}