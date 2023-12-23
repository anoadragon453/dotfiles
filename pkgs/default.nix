self: super: {
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
