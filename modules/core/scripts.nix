{pkgs, config, lib,  ...}:
with lib;
with builtins;

let
  runtimeShell = pkgs.runtimeShell;
  cfg = config.sys.scripts;

  sysTool = pkgs.writeScriptBin "sys" ''
    #!${runtimeShell}

    applyUser() {
      echo "--------------------------------------------------------------------------------"
      echo " Applying User Settings"
      echo "--------------------------------------------------------------------------------"
 

      pushd ~/.dotfiles

      #--impure is required so pacakge can reach out to /etc/hmsystemdata.json
      nix build --impure ".#homeManagerConfigurations.$USER.activationPackage"
      ./result/activate
      popd 
    }

    applyMachine() {
      echo "--------------------------------------------------------------------------------"
      echo " Applying Machine Settings"
      echo "--------------------------------------------------------------------------------"
 
      pushd ~/.dotfiles
      if [ -z "$2" ]; then
        sudo nixos-rebuild switch --flake '.#'

      elif [ $2 = "--boot" ]; then
        sudo nixos-rebuild boot --flake '.#'
      elif [ $2 = "--test" ]; then
        sudo nixos-rebuild test --flake '.#'
      elif [ $2 = "--check" ]; then
        nixos-rebuild dry-activate --flake '.#'
      else
        echo "Unknown option $2"
      fi

      popd
    }

    if [ -n "$INNIXSHELLHOME" ]; then
      echo "You are in a nix shell that redirected home!"
      echo "SYS will not work from here properly."
      exit 1
    fi

    case $1 in
    "clean")
      echo "Running Garbage collection"
      nix-store --gc
      echo "Deduplication running...this may take awhile"
      nix-store --optimise
    ;;

    "update")
      echo "Updating dotfiles flake..."
      pushd ~/.dotfiles
      nix flake update
      popd
    ;;
    "update-index")
      echo "Updating index. This will take a while"
      nix-index
    ;;
    "save")
      echo "Saving changes"
      pushd ~/.dotfiles
      git diff
      git add .
      git commit
      git pull --rebase
      git push
    ;;
    "find")
      if [ $2 = "--overlay" ]; then
        pushd ~/.dotfiles
        nix search .# $3
        popd
      else
        nix search nixpkgs $2
      fi
    ;;

    "find-doc")
      ${pkgs.manix}/bin/manix $2
    ;;

    "find-cmd")
      nix-locate --whole-name --type x --type s --no-group --type x --type s --top-level --at-root "/bin/$2"
    ;;

    "apply")
      applyMachine
      applyUser
    ;;

    "apply-machine")
      applyMachine
    ;;

    "apply-user")
      applyUser
   ;;
    "iso")
      echo "Building iso file $2"
      pushd ~/.dotfiles
      nix build ".#installMedia.$2.config.system.build.isoImage"

      if [ -z "$3" ]; then
        echo "ISO Image is located at ~/.dotfiles/result/iso/nixos.iso"
      elif [ $3 = "--burn" ]; then
        if [ -z "$4" ]; then
          echo "Expected a path to a usb drive following --burn."
        else
          sudo dd if=./result/iso/nixos.iso of=$4 status=progress bs=1M
        fi
      else
        echo "Unexpected option $3. Expected --burn"
      fi
      popd

    ;;
    "shell")
      pushd ~/.dotfiles
      nix develop .#shells.$2 --command zsh
      popd
    ;;

    "installed")
      nix-store -q -R /run/current-system | sed -n -e 's/\/nix\/store\/[0-9a-z]\{32\}-//p' | sort | uniq
    ;;
    "which")
      nix-store -qR $(which $2)
    ;;
    "exec")
      shift 1
      cmd=$1
      pkgs=$(nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$cmd")
      count=$(echo -n "$pkgs" | grep -c "^")

      case $count in
        0)
          >&2 echo "$1: not found!"
          exit 2
        ;;
        1)

          nix-build --no-out-link -A $pkgs "<nixpkgs>"
          if [ "$?" -eq 0 ]; then
            nix-shell -p $pkgs --run "$(echo $@)"
            exit $?
          fi
        ;;
        *)
          PS3="Please select package to run command from:"
          select p in $pkgs
          do
            nix-build --no-out-link -A $p "<nixpkgs>"
            if [ "$?" -eq 0 ]; then
              nix-shell -p $pkgs --run "$(echo $@)"
              exit $?
            fi

            >&2 echo "Unable to run command"
            exit $?
          done
        ;;
      esac
    ;;
    *)
      echo "Usage:"
      echo "sys command"
      echo ""
      echo "Commands:"
      echo "clean - GC and hard link nix store"
      echo "update - Updates dotfiles flake."
      echo "update-index - Updates the index of commands in nixpkgs. Used for exec"
      echo "find [--overlay] - Find a nix package (overlay for custom packages)."
      echo "find-doc - Finds documentation on a config item"
      echo "find-cmd - Finds the package a command is in"
      echo "apply - Applies both user and machine settings"
      echo "apply-machine - Applies current system configuration in dotfiles."
      echo "apply-user - Applies current home manager configuration in dotfiles."
      echo "iso image [--burn path] - Builds nixos install iso and optionally copies to usb."
      echo "shell - runs a shell defined in flake."
      echo "installed - lists all installed packages"
      echo "which - prints the closure of target file"
      echo "exec - executes a command"
    ;;
    esac
  '';
in {
  options.sys.scripts = {
    systemScripts = mkOption {
      default = true;
      description = "Enable system management scripts like sys";
      type = types.bool;
    };
  };

  config = {

    environment.systemPackages = if (cfg.systemScripts) then [ sysTool ] else []; 
  };
}
