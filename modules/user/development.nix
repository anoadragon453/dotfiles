{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
let
    cfg = config.sys;
in {
    system.activationScripts = {
      gpgpubKey.text = ''
        ${pkgs.gnupg}/bin/gpg --import ${./public.asc}
      '';
    };

    sys.user.userRoles.development = [
        (user: mergeUser user {
            files = {
                gpg = {
                    path = ".gnupg/gpg.conf";
                    text = ''
                      personal-cipher-preferences AES256 AES192 AES
                      personal-cipher-preferences AES256 AES192 AES
                      personal-digest-preferences SHA512 SHA384 SHA256
                      personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
                      default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
                      cert-digest-algo SHA512
                      s2k-digest-algo SHA512
                      s2k-cipher-algo AES256
                      charset utf-8
                      fixed-list-mode
                      no-comments
                      no-emit-version
                      keyid-format 0xlong
                      list-options show-uid-validity
                      verify-options show-uid-validity
                      with-fingerprint
                      require-cross-certification
                      no-symkey-cache
                      use-agent
                      throw-keyids

                      #Trust Own GPG Key
                      trusted-key ${user.config.signingKey}
                      default-key ${user.config.signingKey}
                    '';
                };

                gpgAgent = {
                        path = ".gnupg/gpg-agent.conf";
                        text = ''
                            pinentry-program /run/current-system/sw/bin/pinentry-qt
                        '';
                };

            };
        })
    ];
}
