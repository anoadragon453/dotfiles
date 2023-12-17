self: super: {
    g810-led = super.stdenv.mkDerivation {
      pname = "g810led";
      version = "0.4.2";

      src = super.fetchFromGitHub {
        owner = "MatMoul";
        repo = "g810-led";
        rev = "5ee810a520f809e65048de8a8ce24bac0ce34490";
        sha256 = "1ymkp7i7nc1ig2r19wz0pcxfnpawkjkgq7vrz6801xz428cqwmhl";
      };

      buildInputs = [ super.hidapi ];

      patchPhase = ''
        sed -i "s#/usr/bin/#$out/bin/#g" udev/g810-led.rules
        sed -i "s#/usr/bin/#$out/bin/#g" systemd/g810-led.service
        sed -i "s#/usr/bin/#$out/bin/#g" systemd/g810-led-reboot.service
        sed -i "s#/etc/g810-led/profile#$out/etc/g810-led/samples/group_keys#g" systemd/g810-led.service
        sed -i "s#/etc/g810-led/reboot#$out/etc/g810-led/samples/all_off#g" systemd/g810-led-reboot.service
      '';

      buildPhase = ''
        make bin
      '';

      installPhase = ''
       mkdir $out -p
       mkdir $out/etc/g810-led/samples -p
       mkdir $out/etc/udev/rules.d -p
       mkdir $out/lib/systemd/system -p
       cp -R bin $out
       cp udev/g810-led.rules $out/etc/udev/rules.d/g810-led.rules
       cp systemd/* $out/lib/systemd/system
       ln -s $out/bin/g810-led $out/bin/g213-led
       ln -s $out/bin/g810-led $out/bin/g410-led
       ln -s $out/bin/g810-led $out/bin/g413-led
       ln -s $out/bin/g810-led $out/bin/g512-led
       ln -s $out/bin/g810-led $out/bin/g513-led
       ln -s $out/bin/g810-led $out/bin/g610-led
       ln -s $out/bin/g810-led $out/bin/g815-led
       ln -s $out/bin/g810-led $out/bin/gpro-led
       ln -s $out/bin/g810-led $out/bin/g910-led
       cp sample_profiles/* $out/etc/g810-led/samples
      '';
    };

    podman-compose-latest = super.python3.pkgs.buildPythonApplication rec {
      version = "bce40c2db30fb0ffb9264b5f51535c26f48fe983";
      pname = "podman-compose";

      src = super.fetchFromGitHub {
        repo = "podman-compose";
        owner = "containers";
        rev = "${version}";
        sha256 = "sha256-mqQkjjhgnAXpBngbe9Mkf7xXPo3uS0FkqqPetMA6/cg=";
      };

      propagatedBuildInputs = with super.python311Packages; [ pyyaml python-dotenv ];

      meta = {
        description = "An implementation of docker-compose with podman backend";
        homepage = "https://github.com/containers/podman-compose";
        license = super.lib.licenses.gpl2Only;
        platforms = super.lib.platforms.unix;
        maintainers = [ super.lib.maintainers.sikmir ] ++ super.lib.teams.podman.members;
      };
    };

    # packages/pgvecto-rs.nix
    #
    # Author: Diogo Correia <me@diogotc.com>
    # URL:    https://github.com/diogotcorreia/dotfiles
    #
    # A PostgreSQL extension needed for Immich.
    # This builds from the pre-compiled binary instead of from source.
    pgvecto-rs = let 
      # The major version of PostgreSQL that the system is running.
      #
      # TODO: We're still running PostgreSQL 14 as our machine's state.version
      # is 23.11, which implies 14.
      #
      # We would need to upgrade postgres manually and then set the postgres version with
      # services.postgres.package. Probably in its own module?
      #
      # If I was clever, I could set this major version based on the rest of my
      # config itself, like Diogo does.
      major = "14";
      
      # A map from PostgreSQL major version to corresponding pgvecto-rs hash.
      #
      # The pgvecto-rs binary we download depends both on the PostgreSQL major
      # version and the version of pgvecto-rs.
      versionHashes = {
        "14" = "sha256-8YRC1Cd9i0BGUJwLmUoPVshdD4nN66VV3p48ziy3ZbA=";
        "15" = "sha256-IVx/LgRnGyvBRYvrrJatd7yboWEoSYSJogLaH5N/wPA=";
      };
    in super.stdenv.mkDerivation rec {
      pname = "pgvecto-rs";
      version = "0.1.11";

      buildInputs = [ super.dpkg ];

      src = super.fetchurl {
        url =
          "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}-v${version}-x86_64-unknown-linux-gnu.deb";
        hash = versionHashes."${major}";
      };

      dontUnpack = true;
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        mkdir -p $out
        dpkg -x $src $out
        install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
        install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
        install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
        rm -rf $out/usr
      '';

      meta = {
        description =
          "pgvecto.rs extension for PostgreSQL: Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
        homepage = "https://github.com/tensorchord/pgvecto.rs";
      };
    };
}
