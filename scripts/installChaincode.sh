# !/bin/bash
export $BASE_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto

setChaincodeConfig() {  
	echo "... Setting-up chaincode config"
    export FABRIC_CFG_PATH=/etc/hyperledger/fabric/
	export CC_RUNTIME_LANGUAGE=node;
    export CC_NAME=marblesnet;
    export PACKAGE_NAME=marbles
	export CC_SRC_PATH=/opt/gopath/src/github.com/$PACKAGE_NAME;
	export CHANNEL_NAME=claimschannel;
    export VERSION=1
    export SEQUENCE_NO=1
    export CORE_PEER_TLS_ENABLED=true
    export $BASE_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto
    
    export PRIVATE_DATA_CONFIG=/opt/gopath/src/github.com/${PACKAGE_NAME}/private_data_collection/collections_config.json
    export ORDERER_CA=${BASE_PATH}/ordererOrganizations/livwell.com/orderers/orderer.livwell.com/msp/tlscacerts/tlsca.livwell.com-cert.pem
    export PEER0_ORG1_CA=${BASE_PATH}/peerOrganizations/org1.livwell.com/peers/peer0.org1.livwell.com/tls/ca.crt
    export PEER0_ORG2_CA=${BASE_PATH}/peerOrganizations/org2.livwell.com/peers/peer0.org2.livwell.com/tls/ca.crt
}

setPeerEnvironment() {
  export CORE_PEER_MSPCONFIGPATH=${BASE_PATH}/peerOrganizations/$2.livwell.com/users/Admin@$2.livwell.com/msp
  export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_PATH}/peerOrganizations/$2.livwell.com/peers/peer$1.$2.livwell.com/tls/ca.crt
  export CORE_PEER_LOCALMSPID=$2MSP
  if [ $2 == "org1" ]; then
    if [ $1 -eq 0 ]; then
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:7051
    else
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:8051
    fi
  elif [ $2 == "org2" ]; then
    if [ $1 -eq 0 ]; then
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:9051
    else
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:10051
    fi
  else
    echo $'\n'"Failure: Unknown organization provided!"$'\n'
    exit 1
  fi
}

packageChaincode() {
    echo $'\n'""$'\n'
    echo $'\n'"Info: Packging chaincode !"$'\n'

    if ! peer lifecycle chaincode package ${CC_NAME}.tar.gz --path $CC_SRC_PATH --lang $CC_RUNTIME_LANGUAGE --label ${CC_NAME}_${VERSION}; then
        echo $'\n'"Failure: Failed packging chaincode!"$'\n'
        exit 1
    fi
}
installChaincode() {
    # set peer env
    echo $'\n'""$'\n'
    echo $'\n'"Info: Installing chaincode !"$'\n'

    if ! peer lifecycle chaincode install $CC_NAME.tar.gz; then
        echo $'\n'"Failure: Failed installing chaincode!"$'\n'
        exit 1
    fi
}

queryInstalled() {
    rm log.txt
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo " ======= Query installed successful on peer0.org1 on channel ======= "
}


approveChaincode() {

    echo $'\n'""$'\n'
    echo $'\n'"Info: Approving chaincode !"$'\n'
    if ! peer lifecycle chaincode approveformyorg -o orderer.livwell.com:7050 \
        --ordererTLSHostnameOverride orderer.livwell.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --collections-config $PRIVATE_DATA_CONFIG \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE_NO}; then 
        echo $'\n'"Failure: Error approving chaincode!"$'\n'
        exit 1 
    fi
}

checkCommitReadyness() {
    echo " ======= checking commit readiness ======= "
    peer lifecycle chaincode checkcommitreadiness \
        --collections-config $PRIVATE_DATA_CONFIG \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${SEQUENCE_NO} --output json --init-required    
}

commitChaincodeDefination() {
    if ! peer lifecycle chaincode commit -o orderer.livwell.com:7050 \
        --ordererTLSHostnameOverride orderer.livwell.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --peerAddresses peer0.org1.livwell.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
        --peerAddresses peer0.org2.livwell.com:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
        --version ${VERSION} --sequence ${SEQUENCE_NO} --init-required; then
        echo $'\n'"Failure: Error commiting chaincode!"$'\n'
        exit 1
    fi
}

queryCommitted() {
    echo " ======= Query committed chaincode======= "
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}
}

initChaincode() {
    echo $'\n'""$'\n'
    echo $'\n'"Info: Initializing chaincode !"$'\n'
    if ! peer chaincode invoke -o orderer.livwell.com:7050 --ordererTLSHostnameOverride orderer.livwell.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses peer0.org1.livwell.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
        --peerAddresses peer0.org2.livwell.com:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
        --isInit -c '{"function":"initLedger","Args":[]}'; then 
        echo $'\n'"Failure: Error initializing chaincode!"$'\n'
        exit 1 
    fi
    echo " ======= Chaincode initialized successfully ======= "
}
invokeChaincode() {
    ## Create Marble
    peer chaincode invoke -o orderer.livwell.com:7050 \
        --ordererTLSHostnameOverride orderer.livwell.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME}  \
        --peerAddresses peer0.org1.livwell.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
        --peerAddresses peer0.org2.livwell.com:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
        -c '{"function": "initMarble","Args":["marble1", "blue", "35", "tom"]}'

    ## Add private data
    # export CAR=$(echo -n "{\"key\":\"1111\", \"make\":\"Tesla\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"pavan\",\"price\":\"10000\"}" | base64 | tr -d \\n)
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.livwell.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME} \
    #     --peerAddresses peer0.org1.livwell.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
    #     -c '{"function": "createPrivateCar", "Args":[]}' \
    #     --transient "{\"car\":\"$CAR\"}"
}

queryChaincode() {
    echo " ======= Query chaincode ======= "
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["readMarble","marble1"]}'
}

if [ "$1" = "-v" ]; then	
    shift
fi
VERSION=$1;shift

setChaincodeConfig

echo "... packging chaincode"
packageChaincode
echo " ======= Chaincode packaged successfully ======= "

echo "... installing chaincode on org1"
setPeerEnvironment 0 org1
installChaincode
echo " ======= Chaincode installed successfully on peer0.org1 ======= "

setPeerEnvironment 1 org1
installChaincode
echo " ======= Chaincode installed successfully on peer1.org1 ======= "

echo "... installing chaincode on org2"
setPeerEnvironment 0 org2
installChaincode
echo " ======= Chaincode installed successfully on peer0.org2 ======= "

setPeerEnvironment 1 org2
installChaincode
echo " ======= Chaincode installed successfully on peer1.org2 ======= "

echo "... querying chaincode"
setPeerEnvironment 0 org1
queryInstalled

echo "... approving chaincode"
setPeerEnvironment 0 org1
approveChaincode
echo " ======= Chaincode approved successfully by org1 ======= "

setPeerEnvironment 0 org2
approveChaincode
echo " ======= Chaincode approved successfully by org2 ======= "

echo "... commiting chaincode"
setPeerEnvironment 0 org1
checkCommitReadyness
commitChaincodeDefination
queryCommitted    

initChaincode
invokeChaincode
queryChaincode
