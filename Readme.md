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
    docker exec -it cli.survey.themenadesk.com bash
    cd scripts
    ./peer-channel-setup.sh
    ./installChaincode.sh

## To invoke/query a transaction
    peer chaincode invoke -o orderer.themenadesk.com:7050 --ordererTLSHostnameOverride orderer.themenadesk.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/themenadesk.com/orderers/orderer.themenadesk.com/msp/tlscacerts/tlsca.themenadesk.com-cert.pem -C wellness -n survey_cc --peerAddresses peer0.survey.themenadesk.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/survey.themenadesk.com/peers/peer0.survey.themenadesk.com/tls/ca.crt -c '{"function": "initMarble","Args":["marble1", "blue", "35", "tom"]}'

    peer chaincode query -C wellness -n survey_cc -c '{"Args":["readMarble","marble1"]}'

## To stop the network
    docker-compose down

## To prune the network
    docker prune volumes

## To delete all crypro materials & artifacts
    rm -rf channel-artifacts/*
    rm -rf crypto-config/*