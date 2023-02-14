{pkgs, lib}:

{
  contractNames = builtins.attrNames (pkgs.lib.filterAttrs (k: v: v == "directory") (builtins.readDir ./wasm/contracts/.));

  contractMapper = x: pkgs.lib.attrsets.genAttrs contractNames (name: x name);
}