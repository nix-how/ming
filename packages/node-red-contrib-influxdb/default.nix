{
  lib,
  config,
  dream2nix,
  ...
}:
{
  imports = [
    #dream2nix.modules.dream2nix.nodejs-node-modules
    dream2nix.modules.dream2nix.nodejs-package-lock
    dream2nix.modules.dream2nix.nodejs-granular
  ];

  deps = {nixpkgs, ...}: {
    inherit
      (nixpkgs)
      fetchFromGitHub
      mkShell
      stdenv
      ;
  };

  nodejs-package-lock = {
     source = ./.;
#    source = config.deps.fetchFromGitHub {
#      owner = "mblackstock";
#      repo = "node-red-contrib-influxdb";
#      rev = "0.6.1";
#      sha256 = "sha256-tPtj1TzV1sa7/bRBw/w0mGHjuchB4wwhqvlyU+X0hK8=";
#    };
  };

  name = "node-red-contrib-influxdb";
  version = "0.6.1";
  mkDerivation = {
    src = config.nodejs-package-lock.source;
  };
}
