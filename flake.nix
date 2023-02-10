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

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        config = import ./config.nix {};

        rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        craneLibWasm = (crane.mkLib pkgs).overrideToolchain rustWithWasmTarget;

        buildContract = contract:
          craneLibWasm.buildPackage {
            pname = "${config.name}-${contract}";

            src = ./wasm;

            # TODO: Implement optimising steps in post-build
            # buildInputs = [
            #  pkgs.binaryen
            #];

            cargoExtraArgs = "--target=wasm32-unknown-unknown";

            doCheck = false;

            cargoBuildCommand = "RUSTFLAGS='-C link-arg=-s' cargo build --release --lib --locked --package ${contract}";
          };

        deployContract = contract:
          {
            type = "app";
            program = "";
          };

        celestia = import ./tools/celestia.nix { inherit pkgs; };
        wasmd = import ./tools/wasmd.nix { inherit pkgs; };

        contractNames = builtins.attrNames (pkgs.lib.filterAttrs (k: v: v == "directory") (builtins.readDir ./wasm/contracts/.));

        contractMapper = x: pkgs.lib.attrsets.genAttrs contractNames (name: x name);
      in
      {
        packages = {
          celestia = celestia.node;
          wasmd = wasmd.wasmd { libwasmvm = wasmd.libwasmvm; };

          contracts = contractMapper buildContract;

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

        apps = {
          # cel-key: used to generate keys for interacting with the Celestia DA layer
          cel-key = {
            type = "app";
            program = "${celestia.key}/bin/celestia-key";
          };

          # deploy: deploys a smart contract 
          deploy = {
            contracts = contractMapper deployContract;
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