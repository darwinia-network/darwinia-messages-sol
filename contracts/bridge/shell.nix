let
  sources = import ./nix/sources.nix;
  pkgs = import sources.dapptools {};
in
  pkgs.mkShell {
    src = null;
    name = "darwinia-bridge-sol";
    buildInputs = with pkgs; [
      pkgs.dapp
      pkgs.seth
      pkgs.go
      pkgs.go-ethereum-unlimited
      pkgs.hevm
    ];
    LANG="en_US.UTF-8";
  }
