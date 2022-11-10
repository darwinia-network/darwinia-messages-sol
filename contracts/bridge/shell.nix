let
  sources = import ./nix/sources.nix;
  pkgs = import sources.dapptools {};
in
  pkgs.mkShell {
    src = null;
    name = "darwinia-bridge-sol";
    buildInputs = [
      dapp
      seth
      go-ethereum-unlimited
      hevm
      nodejs
    ];
    LANG="en_US.UTF-8";
  }
