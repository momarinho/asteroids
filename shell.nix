{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    ninja
    clang
    lsof
  ];

  buildInputs = with pkgs; [
    gtk3
    glib
    pcre
    libepoxy
    at-spi2-core
    libunwind
    orc
    
    # GStreamer and its plugins
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    
    # Go for backend support
    go
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [
      libGL
      libxkbcommon
      wayland
      libX11
      libXcursor
      libXi
    ])}:$LD_LIBRARY_PATH"
    export GSETTINGS_SCHEMA_DIR="${pkgs.gtk3}/share/glib-2.0/schemas"
  '';
}
