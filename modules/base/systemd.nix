{...}:
{
  config = {

    services.journald.extraConfig = ''
      # Limit the max size of the system journal (syslog).
      #
      # This is mainly to prevent my cloud VMs (with small disk sizes) from
      # filling up.
      SystemMaxUse=500M
    '';

  };
}
