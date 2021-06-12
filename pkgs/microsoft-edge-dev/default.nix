{ lib, stdenv, patchelf, makeWrapper, fetchurl

# Linked dynamic libraries.
, glib, fontconfig, freetype, pango, cairo, libX11, libXi, atk, nss, nspr
, libXcursor, libXext, libXfixes, libXrender, libXScrnSaver, libXcomposite
, libxcb, alsaLib, libXdamage, libXtst, libXrandr, libxshmfence, expat, cups
, dbus, gtk3, gdk-pixbuf, gcc-unwrapped, at-spi2-atk, at-spi2-core, libkrb5
, libdrm, mesa, libxkbcommon, wayland # ozone/wayland

# Command line programs
, coreutils

# command line arguments which are always set e.g "--disable-gpu"
, commandLineArgs ? ""

  # Will crash without.
, systemd

# Loaded at runtime.
, libexif

# Additional dependencies according to other distros.
## Ubuntu
, liberation_ttf, curl, util-linux, xdg-utils, wget
## Arch Linux.
, flac, harfbuzz, icu, libpng, libopus, snappy, speechd
## Gentoo
, bzip2, libcap

  # Necessary for USB audio devices.
, pulseSupport ? true, libpulseaudio ? null

  # Only needed for getting information about upstream binaries
, chromium

, gsettings-desktop-schemas, gnome

# For video acceleration via VA-API (--enable-features=VaapiVideoDecoder)
, libvaSupport ? true, libva

# For Vulkan support (--enable-features=Vulkan)
, vulkanSupport ? true, vulkan-loader }:

with lib;

let
  opusWithCustomModes = libopus.override { withCustomModes = true; };

  deps = [
    glib
    fontconfig
    freetype
    pango
    cairo
    libX11
    libXi
    atk
    nss
    nspr
    libXcursor
    libXext
    libXfixes
    libXrender
    libXScrnSaver
    libXcomposite
    libxcb
    alsaLib
    libXdamage
    libXtst
    libXrandr
    libxshmfence
    expat
    cups
    dbus
    gdk-pixbuf
    gcc-unwrapped.lib
    systemd
    libexif
    liberation_ttf
    curl
    util-linux
    xdg-utils
    wget
    flac
    harfbuzz
    icu
    libpng
    opusWithCustomModes
    snappy
    speechd
    bzip2
    libcap
    at-spi2-atk
    at-spi2-core
    libkrb5
    libdrm
    mesa
    coreutils
    libxkbcommon
    wayland
  ] ++ optional pulseSupport libpulseaudio ++ optional libvaSupport libva
    ++ optional vulkanSupport vulkan-loader ++ [ gtk3 ];

in stdenv.mkDerivation rec {
  pname = "microsoft-edge-dev";
  version = "93.0.910.5";

  src = fetchurl {
    url =
      "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_${version}-1_amd64.deb";
    hash = "sha256-oltQvzYxsasMYUkOn4x+eA2q20iPu/GD4jJ8NHHwbHU=";
  };

  unpackPhase = ''
    ar x $src
    tar xf data.tar.xz
  '';

  rpath = makeLibraryPath deps + ":" + makeSearchPathOutput "lib" "lib64" deps;
  binpath = makeBinPath deps;

  nativeBuildInputs = [ patchelf makeWrapper ];
  buildInputs = [
    # needed for GSETTINGS_SCHEMAS_PATH
    gsettings-desktop-schemas
    glib
    gtk3

    # needed for XDG_ICON_DIRS
    gnome.adwaita-icon-theme
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    exe=$out/bin/microsoft-edge-dev

    mkdir -p $out/bin $out/share

    cp -a opt/* $out/share
    cp -a usr/share/* $out/share

    # To fix --use-gl=egl:
    test -e $out/share/microsoft/msedge-dev/libEGL.so
    ln -s libEGL.so $out/share/microsoft/msedge-dev/libEGL.so.1
    test -e $out/share/microsoft/msedge-dev/libGLESv2.so
    ln -s libGLESv2.so $out/share/microsoft/msedge-dev/libGLESv2.so.2


    substituteInPlace $out/share/applications/microsoft-edge-dev.desktop \
      --replace /usr/bin/microsoft-edge-dev $exe

    substituteInPlace $out/share/gnome-control-center/default-apps/microsoft-edge-dev.xml \
      --replace /opt/microsoft/msedge-dev/microsoft-edge-dev $exe

    substituteInPlace $out/share/menu/microsoft-edge-dev.menu \
      --replace /opt $out/share \
      --replace $out/share/microsoft/msedge-dev/microsoft-edge-dev $exe

    substituteInPlace $out/share/microsoft/msedge-dev/default-app-block \
      --replace /opt/microsoft/msedge-dev/microsoft-edge-dev $exe

    for icon_file in $out/share/microsoft/msedge-dev/product_logo_[0-9]*.png; do
      num_and_suffix="''${icon_file##*logo_}"
      icon_size="''${num_and_suffix%_*}"
      logo_output_prefix="$out/share/icons/hicolor"
      logo_output_path="$logo_output_prefix/''${icon_size}x''${icon_size}/apps"
      mkdir -p "$logo_output_path"
      mv "$icon_file" "$logo_output_path/microsoft-edge-dev.png"
    done

    makeWrapper "$out/share/microsoft/msedge-dev/microsoft-edge-dev" "$exe" \
      --prefix LD_LIBRARY_PATH : "$rpath" \
      --prefix PATH            : "$binpath" \
      --prefix XDG_DATA_DIRS   : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH" \
      --add-flags ${escapeShellArg commandLineArgs}

    for elf in $out/share/microsoft/msedge-dev/{msedge,msedge-sandbox,crashpad_handler,nacl_helper}; do
      patchelf --set-rpath $rpath $elf
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $elf
    done
  '';

  meta = {
    homepage = "https://www.microsoftedgeinsider.com/en-us/";
    description = "Microsoft's fork of Chromium web browser";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "microsoft-edge-dev";
    maintainers = [{
      name = "Amogh Lele";
      email = "amolele@gmail.com";
    }];
  };
}
