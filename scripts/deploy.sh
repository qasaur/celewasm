#!/usr/bin/env bash

TX_HASH=$(wasmd tx wasm store artifacts/cw_nameservice.wasm --from celeswasm-key --keyring-backend test --chain-id celeswasm --gas-prices 0uwasm --gas auto --gas-adjustment 1.3 --node http://127.0.0.1:26657 --output json -y | jq -r '.txhash') && echo $TX_HASH