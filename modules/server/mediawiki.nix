{config, lib, pkgs, ...}:

let
  cfg = config.sys.server.mediawiki;
  phpBool = value: if value then "true" else "false";
  smtpPasswordFile =
    if cfg.smtp.passwordFileSecret != null
    then config.sops.secrets."${cfg.smtp.passwordFileSecret}".path
    else null;

  citizenSkin = pkgs.fetchFromGitHub {
    owner = "StarCitizenTools";
    repo = "mediawiki-skins-Citizen";
    rev = "v3.14.0";
    hash = "sha256-X5OqsuQVFTStMnsZQDhgAdUt9SvKFD+bCKk0IAyC/WI=";
  };

  confirmAccountExtension = pkgs.fetchFromGitHub {
    owner = "wikimedia";
    repo = "mediawiki-extensions-ConfirmAccount";
    rev = "843606aeb4fef9c0aef0e47a01c90a5fd5ebfc98";  # REL1_44; should match Mediawiki version
    hash = "sha256-1sTZCie/SXcts6kH4DRNqGOgqsVGXG9l8idYMzGZKhM=";
  };

  cargoExtension = pkgs.fetchFromGitHub {
    owner = "wikimedia";
    repo = "mediawiki-extensions-Cargo";
    rev = "5f87d10602a2504c6a0e34c86a4955110b7ed49b";  # REL1_44; should match Mediawiki version
    hash = "sha256-F1vPo9Tmb+D4AMU77CTm7w3jfJ8Ra2U0133XODWpEjI=";
  };

  pageFormsExtension = pkgs.fetchFromGitHub {
    owner = "wikimedia";
    repo = "mediawiki-extensions-PageForms";
    rev = "20001f66d9a723b86f8a327a6761cee5056145ef";  # REL1_44; should match Mediawiki version
    hash = "sha256-sgKlaz9skGnigCLs4ZV6aJwfZ81Fx1K7C10PQfuOB4s=";
  };

  templateStylesExtension = pkgs.fetchFromGitHub {
    owner = "wikimedia";
    repo = "mediawiki-extensions-TemplateStyles";
    rev = "c461eb47dcf4b1e0e2466326f389ad32d6cce2b2";  # REL1_44; should match Mediawiki version
    hash = "sha256-0YM9TkFF6V5hpql6iZrsMEcElJgHD/JSn7QaumMooGs=";
  };
in {
  options.sys.server.mediawiki = {
    enable = lib.mkEnableOption "mediawiki";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain to host the Mediawiki instance on";
    };

    name = lib.mkOption {
      type = lib.types.str;
      description = "The public name of the wiki";
    };

    smtp = {
      enable = lib.mkEnableOption "SMTP email delivery for MediaWiki";

      host = lib.mkOption {
        type = lib.types.str;
        default = "ssl://smtp.example.com";
        description = "The SMTP host that MediaWiki should connect to.";
      };

      idHost = lib.mkOption {
        type = lib.types.str;
        default = "wiki.example.com";
        description = "The hostname MediaWiki should present in the SMTP HELO/EHLO exchange.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 465;
        description = "The port of the SMTP server.";
      };

      auth = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether MediaWiki should authenticate to the SMTP server.";
      };

      fromAddress = lib.mkOption {
        type = lib.types.str;
        default = "wiki@example.com";
        description = "The from: address MediaWiki should use when sending emails.";
      };

      username = lib.mkOption {
        type = lib.types.str;
        default = "wiki@example.com";
        description = "The username MediaWiki should use when authenticating to SMTP.";
      };

      passwordFileSecret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "The name of the sops secret containing the SMTP password.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.smtp.enable) || (cfg.smtp.passwordFileSecret != null);
        message = "sys.server.mediawiki.smtp.passwordFileSecret must be set when SMTP is enabled.";
      }
    ];

    services.mediawiki = {
      enable = true;
      webserver = "nginx";
      name = cfg.name;
      url = "https://${cfg.domain}";
      nginx.hostName = cfg.domain;
      #services.mediawiki.uploadsDir
      passwordFile = pkgs.writeText "default-admin-password" "xxxdefaultpassword321";
      extraConfig = ''
        # Disable anonymous editing
        $wgGroupPermissions['*']['edit'] = false;
        
        # Allow any user to create a page
        $wgGroupPermissions['user']['createpage'] = true;

        # Disable anonymous signups
        $wgGroupPermissions['*']['createaccount'] = false;
        # Allow bureaucrats to create accounts.
        # Used to moderate account signups with the ConfirmAccount extension.
        $wgGroupPermissions['bureaucrat']['createaccount'] = true;

        $wgDefaultSkin = 'citizen';

        ${lib.optionalString cfg.smtp.enable ''
          $wgSMTP = [
            'host' => '${cfg.smtp.host}',
            'IDHost' => '${cfg.smtp.idHost}',
            'port' => ${toString cfg.smtp.port},
            'auth' => ${phpBool cfg.smtp.auth},
            'username' => '${cfg.smtp.username}',
            'password' => trim(file_get_contents("${smtpPasswordFile}")),
          ];

          $wgPasswordSender = '${cfg.smtp.fromAddress}';
        ''}

        # ConfirmAccount extension
        
        # The address that will be notified upon an account request being created.
        $wgConfirmAccountContact = '${cfg.smtp.username}';

        # Configure the fields on the account request form.
        $wgMakeUserPageFromBio = false;
        $wgAutoWelcomeNewUsers = false;
        $wgConfirmAccountRequestFormItems = [
          'UserName'        => [ 'enabled' => true ],
          'RealName'        => [ 'enabled' => false ],
          'Biography'       => [ 'enabled' => false, 'minWords' => 50 ],
          'AreasOfInterest' => [ 'enabled' => false ],
          'CV'              => [ 'enabled' => false ],
          'Notes'           => [ 'enabled' => true ],
          'Links'           => [ 'enabled' => false ],
          'TermsOfService'  => [ 'enabled' => false ],
        ];
      '';

      skins = {
        Citizen = citizenSkin;
      };

      extensions = {
        ConfirmAccount = confirmAccountExtension;
        Cargo = cargoExtension;
        PageForms = pageFormsExtension;
        TemplateStyles = templateStylesExtension;
      };
    };

    services.phpfpm.pools.mediawiki.phpOptions = ''
      upload_max_filesize = 10M
      post_max_size = 15M
    '';

    # Enable ACME on the nginx virtual hosts.
    services.nginx.virtualHosts.${cfg.domain} = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
