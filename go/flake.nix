{
  description = "A Nix-flake-based Go development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs = {self, ...} @ inputs: let
    goVersion = 27; # Updated to available Go version

    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config = { permittedInsecurePackages = [ "olm-3.2.16" ]; };
              overlays = [inputs.self.overlays.default];
            };
          }
      );
  in {
    overlays.default = final: prev: {
      go = final."go_1_${toString goVersion}";
    };

    devShells = forEachSupportedSystem (
      {
        pkgs,
        system,
      }: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            # go (version is specified by overlay)
            go

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint

            pre-commit

            self.formatter.${system}

            olm
            pkg-config
            go-tools
            gcc
          ];

          # Set CGO flags for olm
          shellHook = ''
            export PATH="$(go env GOPATH)/bin:$PATH"
            if command -v pkg-config >/dev/null 2>&1; then
              export CGO_CFLAGS="$(pkg-config --cflags olm)"
              export CGO_LDFLAGS="$(pkg-config --libs olm)"
            fi
          '';
        };
      }
    );

    formatter = forEachSupportedSystem ({pkgs, ...}: pkgs.nixfmt);
  };
}
