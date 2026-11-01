{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );

      # Python {major}.{minor} for the venv; changing it rebuilds `.venv` on the next shell load.
      version = "3.13";
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          concatMajorMinor =
            v:
            pkgs.lib.pipe v [
              pkgs.lib.versions.splitVersion
              (pkgs.lib.sublist 0 2)
              pkgs.lib.concatStrings
            ];

          python = pkgs."python${concatMajorMinor version}";
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              python
              pkgs.uv
              self.formatter.${system}

              # Add whatever else you'd like here.
              # pkgs.basedpyright
              # pkgs.ruff
            ];

            env = {
              # Make uv use the Nix interpreter instead of downloading its own.
              UV_PYTHON_PREFERENCE = "only-system";
              UV_PYTHON_DOWNLOADS = "never";
            };

            # The venv is pinned to the exact Nix store interpreter, so a nixpkgs bump or GC recreates it.
            shellHook = ''
              unset PYTHONPATH
              if ! grep -qxF "home = ${python}/bin" .venv/pyvenv.cfg 2>/dev/null; then
                echo "Creating .venv for Python ${python.version}; run 'uv sync' or 'uv pip install ...' to install dependencies"
                uv venv --clear --quiet --python ${python.interpreter} .venv
              fi
              source .venv/bin/activate
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
