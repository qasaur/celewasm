{ pkgs }:
{
  node = pkgs.stdenv.mkDerivation rec {
    pname = "celestia";
    version = "0.6.4";

    src = pkgs.fetchFromGitHub {
      owner = "celestiaorg";
      repo = "celestia-node";
      rev = "v${version}";
      sha256 = "7wmEln3hrNa0RcZg/ZtOaHKT69dibUwcoB30HUcqHPc=";
    };

    buildInputs = [
      pkgs.go
    ];

    configurePhase = '''';

    # TODO: Pass build flags to ensure semantic version etc. is included in the binary
    buildPhase = ''
      export HOME=$(pwd)
      go build -o build/ ./cmd/celestia
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv ./build/celestia $out/bin
    '';
  };

  key = pkgs.stdenv.mkDerivation rec {
    pname = "celestia-key";
    version = "0.6.4";

    src = pkgs.fetchFromGitHub {
      owner = "celestiaorg";
      repo = "celestia-node";
      rev = "v${version}";
      sha256 = "7wmEln3hrNa0RcZg/ZtOaHKT69dibUwcoB30HUcqHPc=";
    };

    buildInputs = [
      pkgs.go
    ];

    configurePhase = '''';

    # TODO: Pass build flags to ensure semantic version etc. is included in the binary
    buildPhase = ''
      export HOME=$(pwd)
      go build -o build/ ./cmd/cel-key
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv ./build/cel-key $out/bin/celestia-key
    '';
  };

  docker = pkgs.dockerTools.buildImage {
    name = "celestia-light";
    tag = "latest";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [ pkgs.bashInteractive ];
      pathsToLink = [ "/bin" ];
    };
  };
}