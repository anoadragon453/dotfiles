{pkgs, ...}:

{
  config = {
    # This is in base because nix makes use of it with flakes.
    sys.software = with pkgs; [ 
      git

      # Allow access to git large-file storage repos.
      git-lfs
    ];

    environment.shellAliases = {
      gp = "git push";
      gpp = "git pull";
      gm = "git commit --amend";
      gc = "git commit";
      gr = "git rebase -i";
    };
  };
}