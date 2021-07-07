# Livwell Hyperledger Fabric Network

## Generate Crypto Materials
    export PATH={PWD}/bin:$PATH
    cryptogen generate -config crypto-config.yaml --output="crypto-config"

## Generate Channel-artifacts
    ./generate-artifacts.sh

## Spinning up the whole network
    docker-compose up

## Channel Setup
    docker exec -it cli.care.livwell.com bash
    cd scripts
    ./peer-channel-setup.sh
    ./installChaincode.sh