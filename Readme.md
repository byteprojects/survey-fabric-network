# Livwell Hyperledger Fabric Network
This project cotains all the essnetials to setup the hylerledger fabric networkv (version: 2.2). 

## Generate Crypto Materials
    export PATH=${PWD}/bin:$PATH
    cryptogen generate --config crypto-config.yaml --output="crypto-config"

## Generate Channel-artifacts
    ./generate-artifacts.sh

## Creating docker overlay network
    docker network create --attachable --driver overlay wellness_network
## Spinning up the whole network
    docker-compose up -d

## Channel Setup
    docker exec -it cli.allparticipants.livwell.com bash
    cd scripts
    ./peer-channel-setup.sh
    ./installChaincode.sh