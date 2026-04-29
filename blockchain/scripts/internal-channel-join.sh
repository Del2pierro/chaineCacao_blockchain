#!/bin/bash
# Internal script to be executed inside CLI container

CHANNEL_NAME="chaincacaochannel"
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt

peer channel create -o orderer.chaincacao.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile $ORDERER_CA
peer channel join -b ${CHANNEL_NAME}.block
