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
      ga = "git add";
      gc = "git commit";
      gch = "git checkout";
      gl = "git log";
      gca = "git commit --amend";
      gcm = "git commit -m";
      gcp = "git cherry-pick";
      gp = "git push";
      gpf = "git push -f";
      gpp = "git pull";
      gr = "git rebase -i";
      gs = "git stash";
      gsp = "git stash pop";
    };
  };
}