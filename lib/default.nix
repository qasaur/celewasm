{pkgs, lib, crane}:

let
  rustWithWasmTarget = pkgs.rust-bin.stable.latest.default.override {
    targets = [ "wasm32-unknown-unknown" ];
  };

  craneLibWasm = (crane.mkLib pkgs).overrideToolchain rustWithWasmTarget;

in rec {
  buildContract = workspaceDir: contract:
    craneLibWasm.buildPackage {
      pname = "${contract}";

      src = workspaceDir;

      # TODO: Implement optimising steps in post-build
      # buildInputs = [
      #  pkgs.binaryen
      #];

      cargoExtraArgs = "--target=wasm32-unknown-unknown";

      doCheck = false;

      cargoBuildCommand = "RUSTFLAGS='-C link-arg=-s' cargo build --release --lib --locked --package ${contract}";
    };

  buildContracts = workspaceDir: contractsDir: (contractMapper dir buildContract);

  deployContracts = dir: contractMapper dir deployContract

  contractNames = dir: builtins.attrNames (pkgs.lib.filterAttrs (k: v: v == "directory") (builtins.readDir dir));

  contractMapper = dir: f: pkgs.lib.attrsets.genAttrs (contractNames dir) (name: f name);

}