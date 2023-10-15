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
      version = "3890eacf57c0643cad6911a0ab23e7e6220c7468";
      pname = "podman-compose";

      src = super.fetchFromGitHub {
        repo = "podman-compose";
        owner = "containers";
        rev = "${version}";
        sha256 = "sha256-IWWI/kR3NCqpNVV6Ukg8CcAa+e/Cfxx2A0TXKTYKYAQ=";
      };

      propagatedBuildInputs = with super.python310Packages; [ pyyaml python-dotenv ];

      meta = {
        description = "An implementation of docker-compose with podman backend";
        homepage = "https://github.com/containers/podman-compose";
        license = super.lib.licenses.gpl2Only;
        platforms = super.lib.platforms.unix;
        maintainers = [ super.lib.maintainers.sikmir ] ++ super.lib.teams.podman.members;
      };
    };
}
