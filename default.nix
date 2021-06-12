{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; }; # functions
  overlays = import ./overlays; # nixpkgs overlays

  microsoft-edge-dev = pkgs.callPackage ./pkgs/microsoft-edge-dev { };
}