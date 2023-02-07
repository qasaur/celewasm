# Celewasm
> A sovereign decentralised roll-up

Celewasm is a barebones decentralised sovereign roll-up, built on Celestia and CosmWasm.

## Development Setup

Install the [Nix Package Manager](https://nixos.org/download.html). Nix is used for all dependency management and is conveniently invoked through a set of helper scripts implemented in the repository.

MacOS:
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Linux:
```sh
sh <(curl -L https://nixos.org/nix/install) 
```

---

```sh
git clone git@github.com:qasaur/celewasm.git
cd celewasm
```

---

## Contracts

Celewasm's core services are written in Rust and compiled to [CosmWasm](https://github.com/CosmWasm/cosmwasm)-compatible contracts. These are located in the `contracts` directory and their interfaces are defined in `packages`. This is roughly correspondent with CosmWasm best practices as illustrated in the [`cw-plus`](https://github.com/CosmWasm/cw-plus) repository.

### Building

```
nix build .#contracts
```

### Developing

```
nix develop .#contracts
```

## Testing

Live testing is done on the Celestia Arabica testnet. The Nix flake defines a set of Nix packages which have all the necessary substitutions to be able to connect to the Celestia data-availability network.

### Developer Environment

Start the wasmd and celestia nodes. These are configured with a set of sane defaults which can be modified in the `config` directory.
```
TODO: nix run .#start-rollup 
```

Contracts defined in `contracts` can be compiled, optimised, and deployed onto the rollup in one command.

```
TODO: nix run .#deploy -- cw20-base
```

### Manual Setup
```
nix run .#celestia -- <command>
```
```
nix run .#wasmd -- <command>
```

## Docker

Docker support is a work-in-progress addition to the repository.

## Release History

* 0.0.1
    * Work in progress