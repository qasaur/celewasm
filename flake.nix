{
  description = "A Celestia/Rollmint/CosmWasm starter pack";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
        url = "github:ipetkov/crane";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        craneLibWasm = (crane.mkLib pkgs).overrideToolchain rustWithWasmTarget;

        celestia = import ./tools/celestia.nix { inherit pkgs; };
        wasmd = import ./tools/wasmd.nix { inherit pkgs; };
      in
      {
        packages = {
          celestia = celestia.node;
          wasmd = wasmd.wasmd { libwasmvm = wasmd.libwasmvm; };

          contracts = craneLibWasm.buildPackage {
            src = ./.;

            doCheck = false;

            # TODO: Implement optimising steps in post-build
            # buildInputs = [
            #  pkgs.binaryen
            #];

            cargoBuildCommand = "RUSTFLAGS='-C link-arg=-s' cargo build --release --lib --target=wasm32-unknown-unknown --locked";
          };

          # Docker scripts

          docker-load = pkgs.symlinkJoin rec {
            name = "docker-load";
            paths = [
              ((pkgs.writeScriptBin name (builtins.readFile (pkgs.substituteAll { src = ./docker/load.sh; image = self.docker.${system}.celestia-light; }))).overrideAttrs(old: {
                buildCommand = "${old.buildCommand}\n patchShebangs $out";
              }))
            ] ++ [
            ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };
        };

        docker = {
          celestia-light = pkgs.dockerTools.buildImage {
            name = "celestia-light";
            tag = "latest";
            created = "now";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [
                self.packages.${system}.celestia
              ];
              pathsToLink = [ "/bin" ];
            };

            config = {
              Entrypoint = "/bin/celestia";
              Workingdir = "/";
            };
          };

          wasmd = pkgs.dockerTools.buildImage {
            name = "wasmd";
            tag = "latest";
            created = "now";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ 
                self.packages.${system}.wasmd
              ];
              pathsToLink = [ "/bin" ];
            };

            config = {
              Entrypoint = [ "/bin/wasmd" ];
              Workingdir = "/";
            };
          };
        };

        apps = {
          # cel-key: used to generate keys for interacting with the Celestia DA layer
          cel-key = {
            type = "app";
            program = "${celestia.key}/bin/celestia-key";
          };

          # start-rollup: starts both the wasmd and celestia light node services with sane defaults
          start-rollup = {
            type = "app";
            program = "";
          };

          # deploy: deploys a smart contract 
          deploy = {
            type = "app";
            program = "";
          };
        };

        devShell = pkgs.mkShell {
          name = "celewasm-shell";

          packages = [
            rustWithWasmTarget

            pkgs.docker
            pkgs.colima

            self.packages.${system}.docker-load
          ];

        };
      }
    );
}