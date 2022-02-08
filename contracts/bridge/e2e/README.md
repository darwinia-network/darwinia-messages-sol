# Local E2E Test

The E2E tests run against local deployments of the drml, ethereum (geth) and bridge.

## Requirements
1. [Nix](https://nixos.org)
```sh
# User must be in sudoers
curl -L https://nixos.org/nix/install | sh

# Run this or login again to use Nix
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```
2. Dapp.tools
```sh
curl https://dapp.tools/install | sh
```

3. Yarn
```sh
brew install yarn@1.22.10
```

4. Rustup && Cargo
```
curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env
rustup default stable
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
```

5. drml
```sh
cargo install --git https://github.com/darwinia-network/darwinia-common  --bin drml
```

## Setup
### Install dependencies
```sh
make install
```

## Launch the testnet
```sh
make local-testnet
```
Wait until the "Testnet has been initialized" message

## E2E tests
Run the tests using the following command:
```bash
yarn test:e2e
```

These tests are meant to closely replicate real-world behaviour.
