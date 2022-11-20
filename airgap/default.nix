{ pkgs ? import <nixpkgs> {} }:
with pkgs.python3Packages; buildPythonApplication {
  pname = "airgap";
  version = "0.0.1";
  src = ./.;
  doCheck = false;
  propagatedBuildInputs = [
    invoke
  ];
}
