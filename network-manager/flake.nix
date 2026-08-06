{
  description = "wsnetworker — C++17 D-Bus network manager dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "network-manager-dev";

      # Make CMake always emit build/compile_commands.json for clangd.
      CMAKE_EXPORT_COMPILE_COMMANDS = "ON";

      packages = with pkgs; [
        # ── Toolchain ────────────────────────────────────────────────────
        gcc
        cmake
        gnumake
        pkg-config
        git

        # ── Debugging & D-Bus Mocking ────────────────────────────────────
        d-spy # Modern D-Bus viewer (replaces d-feet)
        (python3.withPackages (ps: [ps.python-dbusmock])) # Mock hardware

        # ── project library dependencies ─────────────────────────────────
        # sdbus-c++ v2 — matches Docker/CI image (v2.0.0).
        # nixpkgs-unstable ships v2.2.1; both are API-compatible within v2.
        # The plain `sdbus-cpp` attr is v1 (incompatible API) — use _2.
        sdbus-cpp_2
        # apache log4cxx — used directly for structured logging
        log4cxx
        # boost — boost/stacktrace.hpp is used in main.cpp (log4cxx_enable_stacktrace)
        boost
        # googletest + googlemock — unit tests
        gtest
        gdb
        lcov # make module_build_coverage / genhtml
        gcovr # make module_coverage_report / module_coverage_report_html
        cppcheck
        clang-tools # clangd (LSP) + clang-format
      ];

      shellHook = ''
        # Alias to properly run dbusmock with sudo while keeping the Nix python path
        alias mock-modem='sudo $(which python3) -m dbusmock --system --template modemmanager'

        # Symlink compile_commands.json to repo root for clangd, if build exists.
        if [ -f build/compile_commands.json ] && [ ! -e compile_commands.json ]; then
          ln -sf build/compile_commands.json compile_commands.json
        fi
      '';
    };
  };
}
