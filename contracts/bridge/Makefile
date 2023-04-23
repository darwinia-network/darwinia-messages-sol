.PHONY: all install update npm solc fuzz foundry
.PHONY: build test clean doc lint estimate size e2e audit flatten
.PHONY: deploy deploy-mainnet deploy-rinkeby verify check-api-key
.PHONY: local-testnet migrate-local
# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: build

install: solc update npm fuzz

tools: foundry fuzz

# dapp deps
update:; dapp update

# npm deps for linting etc.
npm:; yarn install

fuzz:; go install github.com/hujw77/test-case-generator@v1.0.0
foundry:; cargo install --git https://github.com/foundry-rs/foundry --profile local --locked foundry-cli anvil

# install solc version
# example to install other versions: `make solc SOLC_VERSION=0_8_17`
SOLC_VERSION := ${SOLC_VERSION-0_8_17}
solc:; nix profile install -f https://github.com/dapphub/dapptools/archive/master.tar.gz solc-static-versions.solc_${SOLC_VERSION}

# Build & test
build       :; dapp build
forge-build :; forge build
test        :; dapp test --ffi # enable if you need the `ffi` cheat code on HEVM
forge-test  :; forge test --ffi
flat        :; dapp flat
clean       :; dapp clean
lint        :; yarn run lint
doc         :; yarn run docs
cov         :; @./bin/coverage.sh
audit       :; @./bin/audit.sh
flatten     :; @./bin/flatten.sh
estimate    :; @./bin/estimate-gas.sh ${contract}
size        :; @./bin/contract-size.sh ${contract}
e2e-test    :; @./bin/test.sh
gen-smt     :; export DAPP_SMTCHECKER=1 && dapp mk-standard-json | jq '.settings.modelChecker += {"contracts": {"src/test/utils/Math.p.sol": ["MathPropertyTest"]}, "invariants": ["contract"]}' &> smt.json

# Deployment helpers
deploy      :; @./bin/deploy.sh $(mode)
# Migration
migrate     :; @./bin/migrate.sh $(mode)
# verify
verify      :; @./bin/verify.sh $(mode)
# status
stats       :; @./bin/stats.sh $(mode)

# Local testnet starter
local-testnet :; @./bin/start-services.sh

