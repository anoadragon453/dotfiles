{ config, lib, ... }:

let
  cfg = config.sys.server.postgresql.backups;
in {
  options.sys.server.postgresql.backups = {
    backupLocationFilePath = lib.mkOption {
      type = lib.types.str;
      description = "The directory to store PostgreSQL dumps under";
    };
  };

  config = {
    services.postgresqlBackup = {
      enable = true;
      backupAll = true;
      compression = "zstd";
      location = cfg.backupLocationFilePath;
    };
  };
}