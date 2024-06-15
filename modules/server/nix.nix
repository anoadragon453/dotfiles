{lib, ...}:
{
    # Be much more aggressive about deleting old generations on the
    # servers to conserve disk space.
    nix = {
        gc = {
            options = lib.mkForce "--delete-older-than 1d";
        };
    };
}
