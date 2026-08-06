{
  description = "A Nix-flake-based Node.js development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs = inputs: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [inputs.self.overlays.default];
            };
          }
      );
  in {
    overlays.default = final: prev: rec {
      # nodejs = prev.nodejs;
      nodejs = prev.nodejs_24;
      yarn = prev.yarn.override {inherit nodejs;};
    };

    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            node2nix
            nodejs
            nodePackages.pnpm
            yarn
            pnpm
            bun
          ];
          PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
          # Playwright's downloaded browsers link against the host glibc, so a leaked nix LD_LIBRARY_PATH makes them fail to launch.
          shellHook = ''
            unset LD_LIBRARY_PATH
          '';
        };
      }
    );
  };
}
