# Livwell Hyperledger Fabric Network
This project cotains all the essnetials to setup the hylerledger fabric network (version: 2.2). 

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
    docker exec -it cli.care.livwell.asia bash
    cd scripts
    ./peer-channel-setup.sh
    ./installChaincode.sh

## To invoke/query a transaction
    peer chaincode invoke -o orderer.livwell.asia:7050 --ordererTLSHostnameOverride orderer.livwell.asia --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/livwell.asia/orderers/orderer.livwell.asia/msp/tlscacerts/tlsca.livwell.asia-cert.pem -C wellness -n livwell_cc --peerAddresses peer0.care.livwell.asia:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/care.livwell.asia/peers/peer0.care.livwell.asia/tls/ca.crt -c '{"function": "initMarble","Args":["marble1", "blue", "35", "tom"]}'

    peer chaincode query -C wellness -n livwell_cc -c '{"Args":["readMarble","marble1"]}'

## To stop the network
    docker-compose down

## To prune the network
    docker prune volumes

## To delete all crypro materials & artifacts
    rm -rf channel-artifacts/*
    rm -rf crypto-config/*