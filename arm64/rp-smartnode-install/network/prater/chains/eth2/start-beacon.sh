#!/bin/bash
# This script launches ETH2 beacon clients for Rocket Pool's docker stack; only edit if you know what you're doing ;)


# only show client identifier if version string is under 9 characters
if ((${#ROCKET_POOL_VERSION} < 9)); then
    IDENTIFIER="-${CLIENT::1}"
fi

# Get graffiti text
GRAFFITI="RP${IDENTIFIER^^} $ROCKET_POOL_VERSION"
if [ ! -z "$CUSTOM_GRAFFITI" ]; then
    GRAFFITI="$GRAFFITI ($CUSTOM_GRAFFITI)"
fi


# Lighthouse startup
if [ "$CLIENT" = "lighthouse" ]; then

    CMD="/usr/local/bin/lighthouse beacon --network prater --datadir /ethclient/lighthouse --port $ETH2_P2P_PORT --discovery-port $ETH2_P2P_PORT --eth1 --eth1-endpoints $ETH1_PROVIDER --http --http-address 0.0.0.0 --http-port 5052 --eth1-blocks-per-log-query 150 --disable-upnp"

    if [ ! -z "$ETH2_MAX_PEERS" ]; then
        CMD="$CMD --target-peers $ETH2_MAX_PEERS"
    fi

    exec ${CMD}

fi


# Nimbus startup
if [ "$CLIENT" = "nimbus" ]; then

    # Nimbus won't start unless the validator directories already exist
    mkdir -p /validators/nimbus/validators
    mkdir -p /validators/nimbus/secrets

    CMD="/home/user/nimbus-eth2/build/nimbus_beacon_node --non-interactive --enr-auto-update --network=prater --data-dir=/ethclient/nimbus --log-file=/ethclient/nimbus/nbc_bn_$(date +%Y%m%d%H%M%S).log --tcp-port=$ETH2_P2P_PORT --udp-port=$ETH2_P2P_PORT --web3-url=$ETH1_WS_PROVIDER --rpc --rpc-address=0.0.0.0 --rpc-port=5052 --insecure-netkey-password=true --validators-dir=/validators/nimbus/validators --secrets-dir=/validators/nimbus/secrets"

    if [ ! -z "$ETH2_MAX_PEERS" ]; then
        CMD="$CMD --max-peers=$ETH2_MAX_PEERS"
    fi

    # Graffiti breaks if it's in the CMD string instead of here because of spaces
    exec ${CMD} --graffiti="$GRAFFITI"

fi


# Prysm startup
if [ "$CLIENT" = "prysm" ]; then

    CMD="/app/cmd/beacon-chain/beacon-chain --accept-terms-of-use --prater --genesis-state=/validators/genesis.ssz --datadir /ethclient/prysm --p2p-tcp-port $ETH2_P2P_PORT --p2p-udp-port $ETH2_P2P_PORT --http-web3provider $ETH1_PROVIDER --rpc-host 0.0.0.0 --rpc-port 5052 --eth1-header-req-limit 150"

    if [ ! -z "$ETH2_MAX_PEERS" ]; then
        CMD="$CMD --p2p-max-peers $ETH2_MAX_PEERS"
    fi

    exec ${CMD}

fi


# Teku startup
if [ "$CLIENT" = "teku" ]; then

    CMD="/opt/teku/bin/teku --network=prater --data-path=/ethclient/teku --p2p-port=$ETH2_P2P_PORT --eth1-endpoint=$ETH1_PROVIDER --rest-api-enabled --rest-api-interface=0.0.0.0 --rest-api-port=5052 --rest-api-host-allowlist=* --eth1-deposit-contract-max-request-size=150"

    if [ ! -z "$ETH2_MAX_PEERS" ]; then
        CMD="$CMD --p2p-peer-lower-bound=$ETH2_MAX_PEERS --p2p-peer-upper-bound=$ETH2_MAX_PEERS"
    fi

    exec ${CMD}

fi
