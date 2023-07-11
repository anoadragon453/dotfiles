{pkgs, config, lib, ...}:
with pkgs;
with lib;
with builtins;
let 
    cfg = config.sys;
in {
    options.sys.user = {
        allUsers = {
            files = mkOption {
                type = types.attrs;
                default = {};
                description = "Files to add to all user profiles";
            };
        };

        root = {
            files = mkOption {
                type = types.attrs;
                default = {};
                description = "Files to add to root user profile";
            };

            software = mkOption {
                type = with types; listOf package;
                default = [];
                description = "Software to install as this user";
            };

            shell = mkOption {
                type = types.enum [ "bash" "zsh" "nu"];
                default = "zsh";
                description = "Type of shell to use for this user";
            };

            sshPublicKeys = mkOption {
                type = with types; listOf str;
                default = [];
                description = "Public ssh keys for this user";
            };
        };

        userRoles = mkOption {
            type = with types; attrsOf (listOf anything);
            default = {};
            description = "A role is a list of functions which is run against a user if they are in said role. This allows for user specific machine settings to be split out and only run if a user has the role on a machine."; 
        };

        allUserRoles = mkOption {
            type = with types; listOf str;
            default = [];
            description = "A list of roles that are applied to all users";
        };

        users = mkOption {
            type = with types; attrsOf (submodule {
                options = {
                    files = mkOption {
                        type = types.attrs;
                        default = {};
                        description = "Files to add to the user profile.";
                    };

                    groups = mkOption {
                        type = with types; listOf str;
                        default = [];
                        description = "Extra groups to add to the user.";
                    };

                    software = mkOption {
                        type = with types; listOf package;
                        default = [];
                        description = "Software to install as this user";
                    };

                    roles = mkOption {
                        type = with types; listOf str;
                        default = [];
                        description = "Roles to apply to this user on this machine";
                    };

                    shell = mkOption {
                        type = types.enum [ "bash" "zsh" "nu"];
                        default = "zsh";
                        description = "Type of shell to use for this user";
                    };

                    home = mkOption {
                        type = types.str;
                        default = "";
                        description = "Directory of the users path";
                    };

                    config = mkOption {
                        type = types.attrs;
                        default = {};
                        description = "You can put custom configuration in this section to help configure roles";
                    };

                    sshPublicKeys = mkOption {
                        type = with types; listOf str;
                        default = [];
                        description = "Public ssh keys for this account";
                    };
                };
            });
            default = {};

            description = "Define users of the system here.";
        };
    };

    config = let
      # Generates a shell command that creates a symlink from the `source`
      # filepath to $HOME/.local/share/nix-static/`filename` for the given
      # `user`. Used for linking all the various files from /nix/store into one
      # convenient location. Symlinks should then be created from these files to
      # their respective intended places.
      #
      # Returns the generated command.
      mkUserFile = {user, group, targetPath, sourcePath}: let
        userProfile = "${config.users.users."${user}".home}";
        staticHome = "${userProfile}/.local/share/nix-static";
        targetFolder = dirOf "${staticHome}/${targetPath}";
      in ''
        if [ -f "${staticHome}/${targetPath}" ]; then
          # The file already exists, just append the contents of `sourcePath` to the
          # existing file at `targetPath` under nix-static.
          cat "${sourcePath}" >> "${staticHome}/${targetPath}"
        else
          # The file does not yet exist. Symlink the source file to `targetPath`
          # under nix-static
          install -d -o ${user} -g ${group} "${targetFolder}"
          cp "${sourcePath}" "${staticHome}/${targetPath}"
        fi
        '';

      # Creates a file in the /nix/store with `filename`, containing the
      # contents of `text`. Makes use of mkUserFile to then generate and return a
      # shell command that symlinks the file into $HOME/.local/share/nix-static
      # in the home directory of the given `user`.
      #
      # Returns the generated command.
      mkUserFileFromText = {user, group, filename, targetPath, text}: let
        # Create a file from the given `text` string
        textfile = toFile filename text;
      in mkUserFile { inherit user group targetPath; sourcePath = textfile; };

      mkCleanUp = {user, targetPathUnderHome}: let
        userProfile = "${config.users.users."${user}".home}";
        staticHome = "${userProfile}/.local/share/nix-static";
        targetPath = "${userProfile}/${targetPathUnderHome}";
      in ''
        echo "rm ${targetPath} -fr" >> ${staticHome}/cleanup.sh
        echo "rm ${staticHome}/${targetPathUnderHome} --force" >> ${staticHome}/cleanup.sh
      '';

      mkLinker = {user, targetPathUnderHome, group}: let
        userProfile = "${config.users.users."${user}".home}";
        staticHome = "${userProfile}/.local/share/nix-static";
        targetPath = "${userProfile}/${targetPathUnderHome}";
        targetFolder = dirOf targetPath;
      in ''
        if [[ ! -d "${targetFolder}" ]]; then
          install -d -o ${user} -g ${group} "${targetFolder}"
        fi
        ln -sf "${staticHome}/${targetPathUnderHome}" "${targetPath}"
        chown -h ${user}:${group} "${targetPath}"
      '';

      # Iterate over each attribute of `fileSet` and generate a shell command to symlink
      # from each file in the /nix/store to a file in $HOME/.local/share/nix-static with
      # the same path as described by the `path` attribute of each `fileSet` entry.
      #
      # Example: if the target is $HOME/.config/app.ini, a file will appear at
      # $HOME/.local/share/nix-static/.config/app.ini.
      #
      # If a file already exists in $HOME/.local/share/nix-static with the same path,
      # a command to append the contents of the file in the /nix/store to those in nix-static
      # will be generated instead.
      buildFileScript = {username, group, fileSet}: concatStringsSep "\n" 
        (map (name: (if (hasAttr "source" fileSet."${name}")
          # Return a string that symlinks the `source` file to $HOME/.local/share/nix-static
          then mkUserFile {user = username; group = group; targetPath = fileSet."${name}".path; source = fileSet."${name}".source;}
          # Save the text into a file first, before returning the same as above
          else mkUserFileFromText { user = username; group = group; filename = name; targetPath = fileSet."${name}".path; text = fileSet."${name}".text;}
        )) (attrNames fileSet));

      buildCleanUp = {username, fileSet}: concatStringsSep "\n"
        (map (name: mkCleanUp {
          user = username;
          targetPathUnderHome = fileSet."${name}".path;
        }) (attrNames fileSet));

      # Generate a set of 'ln -sf' commands for each file referenced in `fileSet`
      buildLinker = {username, fileSet, group}: concatStringsSep "\n"
        (map (name: mkLinker {
          user = username;
          targetPathUnderHome = fileSet."${name}".path;
          inherit group;
        }) (attrNames fileSet));

      # Builds and returns an activation script for a given user
      mkBuildScript = {username, fileSet, group ? "users"}: let 
        staticPath = "${config.users.users."${username}".home}/.local/share/nix-static";
        allUserFileSet = cfg.user.allUsers.files;
      in ''
          # Log each line as it executes for easier debugging
          # (slightly inhibits startup time)
          # set -x

          echo "Setting up user files for ${username}"

          # Run the existing cleanup script if it exists.
          # Then delete it to make way for the newly generated version
          if [ -f "${staticPath}/cleanup.sh" ]; then
            "${staticPath}/cleanup.sh"
            rm "${staticPath}/cleanup.sh"
          fi

          # Create the folder to put everything in. We use `install` instead of
          # `mkdir` here as it allows us to set directory ownership permissions
          # (we don't want directories to be owned by root)
          install -d -o ${username} -g ${group} "${staticPath}"

          # Creates files in $HOME/.local/share/nix-static to symlink below
          ${buildFileScript { inherit username group fileSet; }} # files declared specifically for this user
          ${buildFileScript { inherit username group; fileSet = allUserFileSet; }} # files declared for all users

          # Populate cleanup.sh with rm's for any existing declared files for this specific user
          ${buildCleanUp { inherit username fileSet; }}

          # Populate cleanup.sh with rm's for any existing declared files for all users on the system
          ${buildCleanUp { inherit username; fileSet = allUserFileSet; }}

          # Allow the cleanup script to be executable.
          # (chmod will fail if the file doesn't exist)
          if [ -f "${staticPath}/cleanup.sh" ]; then
            chmod +x "${staticPath}/cleanup.sh"
          fi

          echo "Linking user files"

          # Link files declared for this specific user
          ${buildLinker { inherit username fileSet group; }}

          # Link files declared for all users on the system
          ${buildLinker { inherit username group; fileSet = allUserFileSet; }}
        '';

    usersList = attrNames cfg.user.users;

    # ... does something with roles ...
    getRoleFunctions = roles: foldl' (l: r: r ++ l) [] (map (r: cfg.user.userRoles."${r}") (roles ++ cfg.user.allUserRoles));
    applyRoles = {fns, user}: foldl' (u: fn: fn u) user fns;

    # Applies all configured roles to a user
    buildUser = user: let
        fns = getRoleFunctions user.roles;
    in 
        applyRoles { inherit fns user; }; 

    # Build a set mapping from the attribute "text" to {$username = activation script str}.
    userScripts = mapAttrs (n: v: let
        user = buildUser v;
    in { 
        text = mkBuildScript {
            username = n;
            fileSet = user.files; # // cfg.user.allUsers.files;
            group = "users";
        };
    }) cfg.user.users;

    userSettings = listToAttrs( 
     map (v: {
        name = v;
        value = let
            compiledUser = buildUser cfg.user.users."${v}";
            shellpkg = (if (compiledUser.shell == "zsh") then
                pkgs.zsh
            else
                pkgs.bash
            );
        in {
            name = v;
            isNormalUser = true;
            isSystemUser = false;
            extraGroups = compiledUser.groups;
            initialPassword = "P@ssw0rd01";
            packages = compiledUser.software;
            shell = shellpkg;
            openssh.authorizedKeys.keys = compiledUser.sshPublicKeys;
        };
    }) usersList) // {
        root = let
            shellpkg = (if (cfg.user.root.shell == "zsh") then
                pkgs.zsh
            else
                pkgs.bash
            );

        in {
            packages = cfg.user.root.software;
            shell = shellpkg;
            openssh.authorizedKeys.keys = cfg.user.root.sshPublicKeys;
        };
    };

    in {
        # Build a script that is run when this NixOS system configuration is activated.
        # Executed on every system boot and `nixos-rebuild` run.
        system.activationScripts = {
            user-rootFile.text = mkBuildScript { 
                username = "root"; 
                fileSet = cfg.user.root.files; 
                group = "root"; 
            };
        } // userScripts;

        users.users = userSettings;
    };
}
