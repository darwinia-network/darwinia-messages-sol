let
  pkgs = import (builtins.fetchGit rec {
    name = "dapptools-${rev}";
    url = "https://github.com/hujw77/dapptools";
    rev = "2a8a979baf21f36572892368f196601a05043524";
  }) {};

in
  pkgs.mkShell {
    src = null;
    name = "darwinia-bridge";
    buildInputs = with pkgs; [
      pkgs.dapp
      pkgs.seth
      pkgs.go-ethereum-unlimited
      pkgs.hevm
    ];
  }
