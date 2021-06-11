{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; }; # functions
  # modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  microsoft-edge-dev = pkgs.callPackage ./microsoft-edge-dev { };
}