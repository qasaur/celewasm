{ pkgs }:
{
  libwasmvm = pkgs.stdenv.mkDerivation rec {
    pname = "libwasmvm";
    version = "1.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "CosmWasm";
      repo = "wasmvm";
      rev = "v${version}";
      sha256 = "uvZD9zq4GVeqBKwphf+noi3F//aXfRR7dI2KhThL+t0=";
    };

    buildInputs = [
      pkgs.cargo
      pkgs.rustc

      pkgs.libiconv
    ];

    configurePhase = '''';

    buildPhase = ''
      (cd libwasmvm && cargo build --release)
    '';

    # TODO: Make libwasmvm library export cross-platform
    installPhase = ''
      mkdir -p $out/lib
      cp libwasmvm/target/release/libwasmvm.dylib $out/lib/
    '';
  };

  wasmd = { libwasmvm }: pkgs.stdenv.mkDerivation rec {
    pname = "wasmd";
    version = "0.27.0";

    src = pkgs.fetchFromGitHub {
      owner = "CosmWasm";
      repo = "wasmd";
      rev = "v${version}";
      sha256 = "hN7XJDoZ8El2tvwJnW67abhwg37e1ckFyreytN2AwZ0=";
    };

    buildInputs = [
      pkgs.go

      libwasmvm
    ];

    # TODO: Parameterise the pinned replacement versions
    configurePhase = ''
      export HOME=$(pwd)
      echo "replace github.com/cosmos/cosmos-sdk => github.com/rollkit/cosmos-sdk v0.45.10-rollkit-v0.6.0-no-fraud-proofs" >> go.mod
      echo "replace github.com/tendermint/tendermint => github.com/celestiaorg/tendermint v0.34.22-0.20221202214355-3605c597500d" >> go.mod
      go mod tidy -compat=1.17 -e
    '';

    # TODO: Add conditional for non-Darwin builds to statically link
    buildPhase = ''
      export HOME=$(pwd)
      export LEDGER_ENABLED=false
      export LDFLAGS="-r ${pkgs.lib.strings.makeLibraryPath [libwasmvm] }"

      make build
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv ./build/wasmd $out/bin/wasmd
    '';
  };
}