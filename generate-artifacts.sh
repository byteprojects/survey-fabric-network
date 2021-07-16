#!/bin/bash

export PATH=${PWD}/bin:$PATH
export CHANNEL_NAME=wellness
export CHANNEL_ID=system-channel
export ORDERER_PROFILE=OrdererGenesis
export CHANNEL_PROFILE=ChannelGenesis

which configtxgen
if [ "$?" -ne 0 ]; then
  echo "configtxgen tool not found."
  exit 1
fi

generateGenesisBlock() {
  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  configtxgen -profile $ORDERER_PROFILE -configPath . -channelID $CHANNEL_ID -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
}

generateChannelConfiguration() {
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile $CHANNEL_PROFILE -configPath . -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID "$CHANNEL_NAME"
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
}

updateAnchorPeerUpdate() {
  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for $1MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile $CHANNEL_PROFILE -configPath . -outputAnchorPeersUpdate ./channel-artifacts/$1MSPanchors.tx -channelID "$CHANNEL_NAME" -asOrg $1MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for $1..."
    exit 1
  fi
}

generateGenesisBlock
generateChannelConfiguration

updateAnchorPeerUpdate 'care'