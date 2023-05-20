# !/bin/bash
export BASE_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto

setChaincodeConfig() {  
	# Setting-up chaincode config
    export FABRIC_CFG_PATH=/etc/hyperledger/fabric/
	export CC_RUNTIME_LANGUAGE=golang; # either java, golang or node
    export CC_NAME=survey_cc;
    export PACKAGE_NAME=survey-chaincode
	export CC_SRC_PATH=/opt/gopath/src/github.com/$PACKAGE_NAME;
	export CHANNEL_NAME="survey_channel";
    export VERSION=${1:-"1.0"}
    export SEQUENCE_NO=${2:-"1"}
    export CORE_PEER_TLS_ENABLED=true
    export PRIVATE_DATA_CONFIG=/opt/gopath/src/github.com/${PACKAGE_NAME}/private_data_collections/collections_config.json
    export ORDERER_CA=${BASE_PATH}/ordererOrganizations/themenadesk.com/orderers/orderer.themenadesk.com/msp/tlscacerts/tlsca.themenadesk.com-cert.pem
    export PEER0_survey_CA=${BASE_PATH}/peerOrganizations/survey.themenadesk.com/peers/peer0.survey.themenadesk.com/tls/ca.crt

    echo "executing with the following"
    echo "- CHANNEL_NAME: ${CHANNEL_NAME}"
    echo "- CC_NAME: ${CC_NAME}"
    echo "- CC_SRC_PATH: ${CC_SRC_PATH}"
    echo "- CC_SRC_LANGUAGE: ${CC_RUNTIME_LANGUAGE}"
    echo "- CC_SEQUENCE: ${SEQUENCE_NO}"
    echo "- CC_VERSION: ${VERSION}"
}

setPeerEnvironment() {
  export CORE_PEER_MSPCONFIGPATH=${BASE_PATH}/peerOrganizations/$2.themenadesk.com/users/Admin@$2.themenadesk.com/msp
  export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_PATH}/peerOrganizations/$2.themenadesk.com/peers/peer$1.$2.themenadesk.com/tls/ca.crt
  export CORE_PEER_LOCALMSPID=$2MSP
  if [ $2 == "survey" ]; then
    if [ $1 -eq 0 ]; then
      export CORE_PEER_ADDRESS=peer$1.$2.themenadesk.com:7051
    else
      export CORE_PEER_ADDRESS=peer$1.$2.themenadesk.com:8051
    fi
  else
    echo $'\n'"Failure: Unknown organization provided!"$'\n'
    exit 1
  fi
}

packageChaincode() {
    echo $'\n'""$'\n'
    echo $'\n'"Info: Packging chaincode !"$'\n'
    
    echo "Vendoring Go dependencies ..."
	pushd $CC_SRC_PATH
	GO111MODULE=on go mod vendor
	popd
	echo "Finished vendoring Go dependencies"
    
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
    echo " ======= Query installed successful on peer0.survey on channel ======= "
}


approveChaincode() {

    echo $'\n'""$'\n'
    echo $'\n'"Info: Approving chaincode !"$'\n'
    if ! peer lifecycle chaincode approveformyorg -o orderer.themenadesk.com:7050 \
        --ordererTLSHostnameOverride orderer.themenadesk.com \
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
    if ! peer lifecycle chaincode commit -o orderer.themenadesk.com:7050 \
        --ordererTLSHostnameOverride orderer.themenadesk.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --peerAddresses peer0.survey.themenadesk.com:7051 --tlsRootCertFiles $PEER0_survey_CA \
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
    if ! peer chaincode invoke -o orderer.themenadesk.com:7050 --ordererTLSHostnameOverride orderer.themenadesk.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses peer0.survey.themenadesk.com:7051 --tlsRootCertFiles $PEER0_survey_CA \
        --isInit -c '{"function":"initLedger","Args":[]}'; then 
        echo $'\n'"Failure: Error initializing chaincode!"$'\n'
        exit 1 
    fi
    echo " ======= Chaincode initialized successfully ======= "
}
invokeChaincode() {
    ## Create Marble
    peer chaincode invoke -o orderer.themenadesk.com:7050 \
        --ordererTLSHostnameOverride orderer.themenadesk.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME}  \
        --peerAddresses peer0.survey.themenadesk.com:7051 --tlsRootCertFiles $PEER0_survey_CA \
        -c '{"function": "initMarble","Args":["marble1", "blue", "35", "tom"]}'

    ## Add private data
    # export CAR=$(echo -n "{\"key\":\"1111\", \"make\":\"Tesla\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"pavan\",\"price\":\"10000\"}" | base64 | tr -d \\n)
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.themenadesk.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME} \
    #     --peerAddresses peer0.survey.themenadesk.com:7051 --tlsRootCertFiles $PEER0_survey_CA \
    #     -c '{"function": "createPrivateCar", "Args":[]}' \
    #     --transient "{\"car\":\"$CAR\"}"
}

queryChaincode() {
    echo " ======= Query chaincode ======= "
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["readMarble","marble1"]}'
}

setChaincodeConfig $1 $2

echo "... packging chaincode"
packageChaincode
echo " ======= Chaincode packaged successfully ======= "

echo "... installing chaincode on survey"
setPeerEnvironment 0 survey
installChaincode
echo " ======= Chaincode installed successfully on peer0.survey ======= "

setPeerEnvironment 1 survey
installChaincode
echo " ======= Chaincode installed successfully on peer1.survey ======= "
echo "... querying chaincode"
setPeerEnvironment 0 survey
queryInstalled

echo "... approving chaincode"
setPeerEnvironment 0 survey
approveChaincode
echo " ======= Chaincode approved successfully by survey ======= "

echo "... commiting chaincode"
setPeerEnvironment 0 survey
checkCommitReadyness
commitChaincodeDefination
queryCommitted    

initChaincode

# invokeChaincode
# queryChaincode
