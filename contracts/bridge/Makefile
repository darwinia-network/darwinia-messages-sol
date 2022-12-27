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
build    :; dapp build
flat     :; dapp flat
test     :; dapp test --ffi # enable if you need the `ffi` cheat code on HEVM
clean    :; dapp clean
lint     :; yarn run lint
doc      :; yarn run docs
cov      :; @./bin/coverage.sh
audit    :; @./bin/audit.sh
flatten  :; @./bin/flatten.sh
estimate :; @./bin/estimate-gas.sh ${contract}
size     :; @./bin/contract-size.sh ${contract}
gen-smt  :; export DAPP_SMTCHECKER=1 && dapp mk-standard-json | jq '.settings.modelChecker += {"contracts": {"src/test/utils/Math.p.sol": ["MathPropertyTest"]}, "invariants": ["contract"]}' &> smt.json

# Deployment helpers
deploy       :; @./bin/deploy.sh $(network_name)
deploy-local :; @./bin/deploy-local.sh
deploy-test  :; @./bin/deploy-test.sh
deploy-prod  :; @./bin/deploy-prod.sh

# Local testnet starter
local-testnet :; @./bin/start-services.sh

# Migration
migrate-local :; @./bin/migrate-local.sh
migrate-test  :; @./bin/migrate-test.sh
migrate-prod  :; @./bin/migrate-prod.sh

# verify
verify-test:; @./bin/verify-test.sh $(network_name)

# status
msg-sts :; @./bin/stats.sh
