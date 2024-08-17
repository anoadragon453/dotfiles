{pkgs, ...}:

{
  config = {
    # This is in base because nix makes use of it with flakes.
    sys.software = with pkgs; [ 
      git

      # Allow access to git large-file storage repos.
      git-lfs
    ];
  };
}