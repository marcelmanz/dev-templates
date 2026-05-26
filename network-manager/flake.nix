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

      packages = with pkgs; [
        # ── Toolchain ────────────────────────────────────────────────────
        gcc
        cmake
        gnumake
        pkg-config
        git

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
        echo ""
        echo "  wsnetworker dev shell  •  GCC $(gcc --version | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)"
        echo ""
        echo "  make module_build                  build + tests (native)"
        echo "  make module_debug                  debug build"
        echo "  make module_run_test               run unit tests"
        echo "  make module_build_coverage         build with gcov instrumentation"
        echo "  make module_coverage_report_html   HTML coverage report → build/coverage/"
        echo "  make module_clean                  rm -rf build/"
        echo ""
      '';
    };
  };
}
