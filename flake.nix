{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem [flake-utils.lib.system.x86_64-linux] (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        merecat = pkgs.pkgsStatic.merecat;
      in rec {
        formatter = pkgs.alejandra;
        packages = flake-utils.lib.flattenTree {
          docker = pkgs.dockerTools.buildImage {
            name = "merecat";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [
                (pkgs.writeTextDir "etc/passwd" ''
                  root:x:0:0:root:/root:
                  nobody:x:65534:65534:Nobody:/:
                '')
                (pkgs.writeTextDir "etc/shadow" ''
                  root:*:0:0:99999:7:::
                  nobody:*:0:0:99999:7:::
                '')
                (pkgs.runCommand "datadir" {} "mkdir -p $out/data")
                merecat
              ];
              pathsToLink = ["/bin" "/etc" "/data"];
            };

            config = {
              Cmd = ["${merecat}/bin/merecat" "-nrs" "/data"];
            };
          };
        };
        defaultPackage = packages.docker;
      }
    );
}
