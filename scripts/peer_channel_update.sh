#!/bin/bash

echo
echo "Setting Up Hyperledger Fabric Network"
echo
export CHANNEL_NAME="master-channel"
export DELAY=5
export LANGUAGE="node"
export TIMEOUT="15"
export VERBOSE=false
export COUNTER=1
export MAX_RETRY=15
export CORE_PEER_TLS_ENABLED=true
export ORGS="allparticipants"

export BASE_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto
export ORDERER_CA=$BASE_PATH/ordererOrganizations/livwell.com/orderers/orderer.livwell.com/msp/tlscacerts/tlsca.livwell.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

createChannel() {
  setGlobals 0 'allparticipants'
  set -x
  peer channel create -o orderer.livwell.com:7050 \
  -c $CHANNEL_NAME -f ../channel-artifacts/channel.tx \
  --outputBlock ./${CHANNEL_NAME}.block \
  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Channel creation failed"
  echo " ======= Channel '$CHANNEL_NAME' created ======= "
  echo
}

joinChannel() {

  for org in $ORGS; do
    for peer in 0; do
      joinChannelWithRetry $peer $org
      echo " ======= peer${peer}.${org}.livwell.com  joined channel '$CHANNEL_NAME' ======= "
      sleep $DELAY
      echo
    done
  done
}

## Sometimes Join takes time hence RETRY at least 5 times
joinChannelWithRetry() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"

  set -x
  peer channel join -b "$CHANNEL_NAME".block >&log.txt
  res=$?
  set +x
  cat log.txt
}

setGlobals() {
  if [ $2 == "allparticipants" ]; then
    if [ $1 -eq 0 ]; then
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:7051
    fi
    if [ $1 -eq 1 ]; then
      export CORE_PEER_ADDRESS=peer$1.$2.livwell.com:8051
    fi
  fi

  CORE_PEER_TLS_ENABLED=true
  CORE_PEER_LOCALMSPID="$2MSP"
  CORE_PEER_MSPCONFIGPATH=$BASE_PATH/peerOrganizations/$2.livwell.com/users/Admin@$2.livwell.com/msp
  CORE_PEER_TLS_ROOTCERT_FILE=$BASE_PATH/peerOrganizations/$2.livwell.com/peers/peer$1.$2.livwell.com/tls/ca.crt
  CORE_PEER_TLS_CERT_FILE=$BASE_PATH/peerOrganizations/$2.livwell.com/peers/peer$1.$2.livwell.com/tls/server.crt
  CORE_PEER_TLS_KEY_FILE=$BASE_PATH/peerOrganizations/$2.livwell.com/peers/peer$1.$2.livwell.com/tls/server.key
}

updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals "$PEER" "$ORG"

  set -x
  peer channel update -o orderer.livwell.com:7050 \
  -c "$CHANNEL_NAME" -f ../channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx \
  --tls "$CORE_PEER_TLS_ENABLED" --cafile $ORDERER_CA >&log.txt
  res=$?
  set +x
  cat log.txt
  echo " ======= Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ======== "
  sleep "$DELAY"
  echo
}
verifyResult() {
  if [ "$1" -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo " ======= ERROR !!! FAILED to execute  Network Bootstrap ======="
    echo
    exit 1
  fi
}
Create channel
echo "Creating channel..."
createChannel

# Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

Set the anchor peers for each org in the channel
echo "Updating anchor peers for allparticipants..."
updateAnchorPeers 0 'allparticipants'

echo
echo " ======= All GOOD, Hyperledger Fabric Network Is Now Up and Running! ======="
echo

exit 0