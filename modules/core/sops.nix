{lib, ...}:

{
  config = {
    # Don't automatically import ssh keys as age keys.
    sops.age.sshKeyPaths = [];
    sops.gnupg.sshKeyPaths = [];

    # Where the age keyfile is expected to be (or where it will be generated
    # in the case of a VM).
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # VM variants should just generate an age key, while live servers shouldn't.
    # We can then copy the generated age key from the VM onto the live server before deploying.
    sops.age.generateKey = false;
    virtualisation.vmVariant = {
      sops.age.generateKey = lib.mkForce true;
    };
  };
}
