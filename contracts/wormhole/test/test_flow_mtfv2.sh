#export VER=production;
export CONFIG=./deploy/mapping-token-v2/v2_darwinia_to_bsc.json;
yarn deploy-local ./deploy/mapping-token-v2/generate_config_template.js
yarn deploy-local ./deploy/mapping-token-v2/deploy_mtf_v2.js
yarn deploy-local ./deploy/mapping-token-v2/deploy_backing_v2.js
export DEPOSITOR="backing";
yarn deploy-local ./deploy/mapping-token-v2/deploy_guard_v2.js
export DEPOSITOR="mappingTokenFactory";
yarn deploy-local ./deploy/mapping-token-v2/deploy_guard_v2.js
yarn deploy-local ./deploy/mapping-token-v2/deploy_erc20_v2.js
yarn deploy-local ./deploy/mapping-token-v2/configure_mtf_v2.js
yarn deploy-local ./deploy/mapping-token-v2/configure_backing_v2.js
