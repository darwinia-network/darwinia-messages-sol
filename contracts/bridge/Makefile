.PHONY: all install update npm solc
.PHONY: build test clean doc lint estimate size e2e
.PHONY: deploy deploy-mainnet deploy-rinkeby verify check-api-key
.PHONY: local-testnet migrate-local
# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: build

install: solc update npm

# dapp deps
update:; dapp update

# npm deps for linting etc.
npm:; yarn install

# install solc version
# example to install other versions: `make solc SOLC_VERSION=0_8_2`
SOLC_VERSION := ${SOLC_VERSION-0_7_6}
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_${SOLC_VERSION}

# Build & test
build    :; dapp build
test     :; dapp test # --ffi # enable if you need the `ffi` cheat code on HEVM
clean    :; dapp clean
lint     :; yarn run lint
doc      :; yarn run docs
estimate :; @./bin/estimate-gas.sh ${contract}
size     :; @./bin/contract-size.sh ${contract}

# Deployment helpers
deploy       :; @./bin/deploy.sh $(network_name)
deploy-local :; @./bin/deploy-local.sh
deploy-test  :; @./bin/deploy-test.sh

# Local testnet starter
local-testnet :; @./bin/start-services.sh

# Migration
migrate-local :; @./bin/migrate-local.sh
migrate-test  :; @./bin/migrate-test.sh

# verify
verify-test:; @./bin/verify-test.sh $(network_name)

# status
msg-sts :; @./bin/stats.sh
