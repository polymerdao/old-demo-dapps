//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import '../base/UniversalChanIbcApp.sol';

contract XProofOfVoteNFTUC is ERC721, UniversalChanIbcApp {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string tokenURIPolyVote;

    constructor(address _middleware, string memory _tokenURIPolyVote) 
        ERC721("UniversalProofOfVoteNFT", "Polymeranian2")
        UniversalChanIbcApp(_middleware) {
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

    // IBC methods

    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address decodedVoter, address decodedRecipient, uint decodedVoteId) = abi.decode(packet.appData, (address, address, uint));

        uint256 voteNFTId = mint(decodedRecipient);

        bytes memory ackData = abi.encode(decodedVoter, voteNFTId);

        return AckPacket(true, ackData);
    }

    function onUniversalAcknowledgement(
            bytes32 channelId,
            UniversalPacket memory packet,
            AckPacket calldata ack
    ) external override onlyIbcMw {
        require(false, "This function should not be called");
    }

    function onTimeoutUniversalPacket(
        bytes32 channelId, 
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        require(false, "This function should not be called");
    }
}
