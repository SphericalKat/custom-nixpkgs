{ lib, stdenv, patchelf, fetchurl, appimageTools }:

with lib;

let
  name = "jetbrains-toolbox";
  version = "1.20.8804";
  sha256 = "3b76620cbe5118b457931cfb4605ca4d8df488f543a1b8c63f63214500872e5d";
in rec {
  jetbrains-toolbox-src = stdenv.mkDerivation {
    name = "jetbrains-toolbox-src";

    src = fetchurl {
      url = "https://download.jetbrains.com/toolbox/${name}-${version}.tar.gz";
      inherit sha256;
    };

    installPhase = ''
      #mkdir -p $out/bin
      cp jetbrains-toolbox $out
    '';
  };

  jetbrains-toolbox = appimageTools.wrapType2 {
    inherit name;

    src = jetbrains-toolbox-src;

    extraPkgs = pkgs: with pkgs; [ libcef ];

    meta = {
      description = "Manage all your JetBrains Projects and Tools";
      longDescription = ''
        The JetBrains Toolbox lets you install and manage JetBrains Products in muiltiple versions.
      '';
      homepage = "https://www.jetbrains.com/toolbox/";
      platforms = platforms.all;
			license = licenses.unfree;
      maintainers = [{
        name = "Amogh Lele";
        email = "amolele@gmail.com";
      }];
    };
  };
}
