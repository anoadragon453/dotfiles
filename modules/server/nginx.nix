{ ... }:

{
  config = {
    services.nginx = {
      # Set some reasonable defaults for all virtual hosts.
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      # TODO: nginx: [warn] could not build optimal proxy_headers_hash, you should increase either proxy_headers_hash_max_size: 512 or proxy_headers_hash_bucket_size: 64; ignoring proxy_headers_hash_bucket_size
      # appendConfig = ''
      #   proxy_headers_hash_max_size 512;
      # '';
    };

    # Open the typical HTTP ports.
    networking.firewall.allowedTCPPorts = [
      80 443
    ];
  };
}