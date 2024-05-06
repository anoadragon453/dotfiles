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
      gb = "git branch";
      gc = "git commit";
      gch = "git checkout";
      gd = "git diff";
      gl = "git log";
      gca = "git commit --amend";
      gcm = "git commit -m";
      gcp = "git cherry-pick";
      gf = "git fetch";
      gp = "git push";
      gpf = "git push -f";
      gpl = "git pull";
      gr = "git rebase -i";
      gs = "git stash";
      gsp = "git stash pop";
    };
  };
}