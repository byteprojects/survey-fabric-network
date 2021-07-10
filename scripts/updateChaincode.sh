#!/bin/bash

setChaincodeConfig() {  
	echo "... Setting-up chaincode config"
	CC_RUNTIME_LANGUAGE=node;
	CC_SRC_PATH=/opt/gopath/src/github.com/Trueclaim-Smartcontract;
	CC_NAME=Trueclaim-Smartcontract;
	CHANNEL_NAME=claimschannel;
  
  CA_FILE_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trueclaim.network/orderers/orderer.trueclaim.network/msp/tlscacerts/tlsca.trueclaim.network-cert.pem
  COLLECTION_PATH=/opt/gopath/src/github.com/Trueclaim-Smartcontract/private_data_collection/collections_config.json
}

setPeerEnvironment() {

  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$2.trueclaim.network/users/Admin@$2.trueclaim.network/msp
	CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$2.trueclaim.network/peers/$1.$2.trueclaim.network/tls/ca.crt
  CORE_PEER_LOCALMSPID=$2MSP
	CORE_PEER_ADDRESS=$1.$2.trueclaim.network:7051
}

installChaincode() {
    
    echo $'\n'""$'\n'
    echo $'\n'"Info: Installing chaincode !"$'\n'

    if ! peer chaincode install -n $CC_NAME -v $1 -p $CC_SRC_PATH -l $CC_RUNTIME_LANGUAGE; then
        echo $'\n'"Failure: Failed installing chaincode!"$'\n'
        exit 1 
    fi
}

instantiateChaincode() {

    echo $'\n'""$'\n'
    echo $'\n'"Info: Instantiating chaincode !"$'\n'

    if ! peer chaincode instantiate -o orderer.trueclaim.network:7050 -C $CHANNEL_NAME --tls --cafile $CA_FILE_PATH -n $CC_NAME -l node -v $1 -c '{"Args":[]}' -P "OR ('TrueCoverMSP.member','TrueCoverMSP.peer', 'TrueCoverMSP.admin', 'TrueCoverMSP.client', 'ClaimAdministratorsMSP.member','ClaimAdministratorsMSP.peer', 'ClaimAdministratorsMSP.admin', 'ClaimAdministratorsMSP.client', 'InsurersMSP.member','InsurersMSP.peer', 'InsurersMSP.admin', 'InsurersMSP.client', 'ProvidersMSP.member','ProvidersMSP.peer', 'ProvidersMSP.admin', 'ProvidersMSP.client')" --collections-config  $COLLECTION_PATH; then 
        echo $'\n'"Failure: Error instantiating chaincode!"$'\n'
        exit 1 
    fi
}

upgradeChaincode() {

    echo $'\n'""$'\n'
    echo $'\n'"Info: Instantiating chaincode !"$'\n'

    if ! peer chaincode upgrade -o orderer.trueclaim.network:7050 -C $CHANNEL_NAME --tls --cafile $CA_FILE_PATH -n $CC_NAME -l node -v $1 -c '{"Args":[]}' -P "OR ('TrueCoverMSP.member','TrueCoverMSP.peer', 'TrueCoverMSP.admin', 'TrueCoverMSP.client', 'ClaimAdministratorsMSP.member','ClaimAdministratorsMSP.peer', 'ClaimAdministratorsMSP.admin', 'ClaimAdministratorsMSP.client', 'InsurersMSP.member','InsurersMSP.peer', 'InsurersMSP.admin', 'InsurersMSP.client', 'ProvidersMSP.member','ProvidersMSP.peer', 'ProvidersMSP.admin', 'ProvidersMSP.client')" --collections-config  $COLLECTION_PATH; then 
        echo $'\n'"Failure: Error instantiating chaincode!"$'\n'
        exit 1 
    fi
}

if [ "$1" = "-v" ]; then	
    shift
fi
VERSION=$1;shift

setChaincodeConfig

echo "... installing chaincode on claimadministrators"
setPeerEnvironment peer0 claimadministrators
installChaincode $VERSION

setPeerEnvironment peer1 claimadministrators
installChaincode $VERSION

echo "... installing chaincode on providers"
setPeerEnvironment peer0 providers
installChaincode $VERSION

setPeerEnvironment peer1 providers
installChaincode $VERSION

echo "... upgrading chaincode from claimadministrators"
setPeerEnvironment peer0 claimadministrators
instantiateChaincode $VERSION