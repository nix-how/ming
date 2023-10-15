{
  description = "My flake with dream2nix packages";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
    nixos-shell.url = "github:mic92/nixos-shell";
  };

  outputs = inputs @ {
    self,
    dream2nix,
    nixpkgs,
    nixos-shell,
    ...
  }: let
    system = "x86_64-linux";
  in {
    apps.x86_64-linux.nixos-shell = {
      type = "app";
      program = builtins.toPath (inputs.nixpkgs.legacyPackages.x86_64-linux.writeShellScript "run-binfmt-sdk-nixos-shell" ''
        rm nixos.qcow2 || true
        function cleanup {
          rm nixos.qcow2
        }
        export NIX_CONFIG="experimental-features = nix-command flakes"
        export PATH=$PATH:${inputs.nixpkgs.legacyPackages.x86_64-linux.nixUnstable}/bin
        ${inputs.nixos-shell.packages.x86_64-linux.nixos-shell}/bin/nixos-shell --flake ${self}#vm
        trap cleanup 0
      '');
    };
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem { system = "x86_64-linux"; modules = [ ./vm.nix nixos-shell.nixosModules.nixos-shell ]; specialArgs = { node-red-contrib-influxdb = self.packages.x86_64-linux.node-red-contrib-influxdb; }; };
    # all packages defined inside ./packages/
    packages.${system} = dream2nix.lib.importPackages {
      projectRoot = ./.;
      # can be changed to ".git" or "flake.nix" to get rid of .project-root
      projectRootFile = "flake.nix";
      packagesDir = ./packages;
      packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
    };
  };
}
