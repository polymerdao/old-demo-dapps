// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import './vibc-core/Ibc.sol';
import './vibc-core/IbcReceiver.sol';
import './vibc-core/IbcDispatcher.sol';

contract IbcProofOfVoteNFT is ERC721, IbcReceiver, IbcReceiverBase {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    /** 
     * 
     * IBC storage variables
     * 
     */ 

    // received packet as chain B
    IbcPacket[] public recvedPackets;
    // received ack packet as chain A
    bytes32[] public connectedChannels;

    string[] supportedVersions;

    string tokenURIPolyVote;

    constructor(IbcDispatcher _dispatcher, string memory _tokenURIPolyVote) 
        ERC721("PolyVoter", "POLYV") IbcReceiverBase(_dispatcher) 
        {
            supportedVersions = ['1.0', '2.0'];
            tokenURIPolyVote = _tokenURIPolyVote;
        }

    function mint(address recipient)
        public
        returns (uint256)
    {
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return tokenURIPolyVote;
    }

    function updateTokenURI(string memory _newTokenURI) public {
        tokenURIPolyVote = _newTokenURI;
    }

     /** 
      * 
      * IBC packet callbacks
      * 
      */    
    
    function onRecvPacket(IbcPacket calldata packet) external onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        recvedPackets.push(packet);

        (address decodedVoter, address decodedRecipient, uint decodedVoteId) = abi.decode(packet.data, (address, address, uint));

        uint256 voteNFTId = mint(decodedRecipient);

        bytes memory ackData = abi.encode(decodedVoter, voteNFTId);

        return AckPacket(true, ackData);
    }

    // should not be called
    function onAcknowledgementPacket(IbcPacket calldata packet, AckPacket calldata ack) external onlyIbcDispatcher {
        // TODO add error
    }

    // should not be called
    function onTimeoutPacket(IbcPacket calldata packet) external onlyIbcDispatcher {
        // TODO add error
    }

    /** 
     * 
     * IBC channel callbacks
     * 
     */ 

    function onOpenIbcChannel(
        string calldata version,
        ChannelOrder ordering,
        bool feeEnabled,
        string[] calldata connectionHops,
        string calldata counterpartyPortId,
        bytes32 counterpartyChannelId,
        string calldata counterpartyVersion
    ) external onlyIbcDispatcher returns (string memory selectedVersion) {
        if (bytes(counterpartyPortId).length <= 8) {
            revert invalidCounterPartyPortId();
        }
        /**
         * Version selection is determined by if the callback is invoked on behalf of ChanOpenInit or ChanOpenTry.
         * ChanOpenInit: self version should be provided whereas the counterparty version is empty.
         * ChanOpenTry: counterparty version should be provided whereas the self version is empty.
         * In both cases, the selected version should be in the supported versions list.
         */
        bool foundVersion = false;
        selectedVersion = keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked(''))
            ? counterpartyVersion
            : version;
        for (uint i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(selectedVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');

        return selectedVersion;
    }

    function onConnectIbcChannel(
        bytes32 channelId,
        bytes32 counterpartyChannelId,
        string calldata counterpartyVersion
    ) external onlyIbcDispatcher {
        // ensure negotiated version is supported
        bool foundVersion = false;
        for (uint i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(counterpartyVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');
        connectedChannels.push(channelId);
    }

    function onCloseIbcChannel(
        bytes32 channelId,
        string calldata counterpartyPortId,
        bytes32 counterpartyChannelId
    ) external onlyIbcDispatcher {
        // logic to determin if the channel should be closed
        bool channelFound = false;
        for (uint i = 0; i < connectedChannels.length; i++) {
            if (connectedChannels[i] == channelId) {
                delete connectedChannels[i];
                channelFound = true;
                break;
            }
        }
        require(channelFound, 'Channel not found');
    }
}