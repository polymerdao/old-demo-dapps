// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import './vibc-core/Ibc.sol';
import './vibc-core/IbcReceiver.sol';
import './vibc-core/IbcDispatcher.sol';
import './vibc-core/IbcMiddleware.sol';

contract IbcProofOfVoteNFT is ERC721, IbcMwUser, IbcUniversalPacketReceiver {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    /** 
     * 
     * IBC storage variables
     * 
     */ 

    struct UcPacketWithChannel {
        bytes32 channelId;
        UniversalPacket packet;
    }

    struct UcAckWithChannel {
        bytes32 channelId;
        UniversalPacket packet;
        AckPacket ack;
    }

    // received packet as chain B
    UcPacketWithChannel[] public recvedPackets;

    string tokenURIPolyVote;

    constructor(address _middleware, string memory _tokenURIPolyVote) 
        ERC721("PolyVoter", "POLYV") IbcMwUser(_middleware) 
        {
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
    
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address decodedVoter, address decodedRecipient, uint decodedVoteId) = abi.decode(packet.appData, (address, address, uint));

        uint256 voteNFTId = mint(decodedRecipient);

        bytes memory ackData = abi.encode(decodedVoter, voteNFTId);

        return AckPacket(true, ackData);
    }

    // should not be called
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket calldata packet, AckPacket calldata ack) external onlyIbcMw {
        // TODO add error
    }

    // should not be called
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external onlyIbcMw {
        // TODO add error
    }
}