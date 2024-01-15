// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@open-ibc/vibc-core-smart-contracts/contracts/Ibc.sol";
import "@open-ibc/vibc-core-smart-contracts/contracts/IbcReceiver.sol";
import "@open-ibc/vibc-core-smart-contracts/contracts/IbcDispatcher.sol";

error invalidCounterPartyPortId();

/**
 * @title mintAndTransfer
 * @dev can mint and NFT and transfer it to a destiniation chain via IBC
 */
contract nftTransfer is IbcReceiver, Ownable, ERC721 {
    using Strings for uint256;
    string private constant TOKEN_URI =
        "https://raw.githubusercontent.com/bbehrman10/sampleNFTMetaData/main/metadata.json";
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    mapping(uint256 => bool) private _lockedTokens; // You can either lock the NFT by setting this mapping (cheaper) or
    // mapping(uint256 => address) private _originalOwners; // You can lock the NFT by setting the owner as this contact and preserving the original owner (more secure)
    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTLocked(address indexed owner, uint256 indexed tokenId);
    event NFTUnlocked(address indexed owner, uint256 indexed tokenId);
    event NFTTransferred(
        address indexed owner,
        uint256 indexed tokenId,
        address destinationAddress,
        bytes packetData
    );

    struct NonFungibleTokenPacketData {
        string classId;
        string classUri;
        string classData;
        string[] tokenIds;
        string[] tokenUris;
        string[] tokenData;
        address sender;
        address receiver;
        string memo;
    }

    constructor(
        // string memory _name,
        // string memory _symbol
    ) ERC721("nftName", "SYM") {
        //run the mint function here to mint the NFT for the sake of this example
        mintNFT(msg.sender);
    }

    function mintNFT(address recipient) public onlyOwner returns (uint256) {
        currentTokenId.increment();
        _safeMint(recipient, currentTokenId.current());
        emit NFTMinted(recipient, currentTokenId.current());
        return currentTokenId.current();
    }

    function tokenURI(uint256 tokenId) virtual override public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return TOKEN_URI;
    }

    function lockNFT(uint256 tokenId) internal {
        _lockedTokens[tokenId] = true;
        emit NFTLocked(ownerOf(tokenId), tokenId);
    }

    function unlockNFT(uint256 tokenId) internal {
        _lockedTokens[tokenId] = false;
        emit NFTUnlocked(ownerOf(tokenId), tokenId);
    }

    function getClassId(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 classId = tokenId >> 128;
        return Strings.toHexString(classId, 32);
    }

    function transferNFT(
        uint256 tokenId,
        address senderAddress,
        address recipientAddress,
        string memory memo,
        PacketFee calldata fee
    ) internal  returns (bytes memory){
        require(_lockedTokens[tokenId] == true, "This token is not locked");
        NonFungibleTokenPacketData
            memory packetData = NonFungibleTokenPacketData({
                classId: getClassId(tokenId),
                classUri: "https://raw.githubusercontent.com/bbehrman10/sampleNFTMetaData/main/metadata.json",
                classData: "",
                tokenIds: new string[](1),
                tokenUris: new string[](1),
                tokenData: new string[](1),
                sender: senderAddress,
                receiver: recipientAddress,
                memo: memo
            });
        packetData.tokenIds[0] = tokenId.toString();
        packetData.tokenUris[0] = tokenURI(tokenId);
        packetData.tokenData[0] = "additional data here";

        bytes memory payload = abi.encode(packetData);
        uint64 timeoutTimestamp = uint64(
            (block.timestamp + 36000) * 1000000000
        );
        // uncomment when actually sending the packet
        // bytes32 channelId = connectedChannels[0];

        // vibcDispatcher.sendPacket{value: Ibc.calcEscrowFee(fee)}(
        //     channelId,
        //     payload,
        //     timeoutTimestamp,
        //     fee
        // );
        return payload;
    }

    function initiateNFTTransfer(
        uint256 tokenId,
        address destinationAddress,
        string memory memo,
        PacketFee calldata fee
    ) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        lockNFT(tokenId);
        //transfer nft to destination chain
        bytes memory data = transferNFT(tokenId, msg.sender, destinationAddress, memo, fee);
        emit NFTTransferred(
            msg.sender,
            tokenId,
            destinationAddress,
            data
        );
    }

    ///*** IBC storage variables ***///

    // received ack packet as chain A
    AckPacket[] public ackPackets;
    // received timeout packet as chain A
    IbcPacket[] public timeoutPackets;
    IbcPacket[] public recvedPackets;
    bytes32[] public connectedChannels;

    string[] public supportedVersions;

    // vIBC core Dispatcher address on OP sepolia
    IbcDispatcher public vibcDispatcher; //'0x7a1d713f80BFE692D7b4Baa4081204C49735441E'

    /**
     *
     * @param feeEnabled in production, you'll want to enable this to avoid spamming create channel calls (costly for relayers)
     * @param connectionHops 2 connection hops to connect to the destination via Polymer
     * @param counterparty the address of the destination chain contract you want to connect to
     * @param proof not implemented for now
     */
    function createChannel(
        bool feeEnabled,
        string[] calldata connectionHops,
        CounterParty calldata counterparty,
        Proof calldata proof
    ) external {
        vibcDispatcher.openIbcChannel(
            IbcReceiver(address(this)),
            supportedVersions[0],
            ChannelOrder.UNORDERED,
            feeEnabled,
            connectionHops,
            counterparty,
            proof
        );
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory b = bytes(s);
        for (uint i = 0; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint256(uint8(b[i])) - 48);
            } else {
                // Character is not a number
                revert("String contains non-numeric characters");
            }
        }
        return result;
    }

    /**
     * IBC Packet Callbacks
     */

    function onRecvPacket(
        IbcPacket calldata packet
    ) external returns (AckPacket memory ackPacket) {
        recvedPackets.push(packet);
        // decode the packet data and unlock or mint the NFT
        NonFungibleTokenPacketData memory decodedPacketData = abi.decode(
            packet.data,
            (NonFungibleTokenPacketData)
        );
        uint256 tokenId = stringToUint(decodedPacketData.tokenIds[0]);
        if (_lockedTokens[tokenId]) {
            unlockNFT(tokenId);
        } else {
            mintNFT(decodedPacketData.receiver);
        }
        bytes memory ackData = abi.encode(
            decodedPacketData.receiver,
            decodedPacketData.tokenIds[0]
        );
        return AckPacket(true, ackData);
    }

    function onAcknowledgementPacket(
        IbcPacket calldata packet,
        AckPacket calldata ack
    ) external {
        ackPackets.push(ack);
        // decode the ack data and do something with it
    }

    function onTimeoutPacket(IbcPacket calldata packet) external {
        timeoutPackets.push(packet);
    }

    /**
     * IBC Channel Callbacks
     */

    function onOpenIbcChannel(
        string calldata version,
        ChannelOrder ordering,
        bool feeEnabled,
        string[] calldata connectionHops,
        string calldata counterpartyPortId,
        bytes32 counterpartyChannelId,
        string calldata counterpartyVersion
    ) external view returns (string memory selectedVersion) {
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
        selectedVersion = keccak256(abi.encodePacked(version)) ==
            keccak256(abi.encodePacked(""))
            ? counterpartyVersion
            : version;
        for (uint i = 0; i < supportedVersions.length; i++) {
            if (
                keccak256(abi.encodePacked(selectedVersion)) ==
                keccak256(abi.encodePacked(supportedVersions[i]))
            ) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, "Unsupported version");

        return selectedVersion;
    }

    function onConnectIbcChannel(
        bytes32 channelId,
        bytes32 counterpartyChannelId,
        string calldata counterpartyVersion
    ) external {
        // ensure negotiated version is supported
        bool foundVersion = false;
        for (uint i = 0; i < supportedVersions.length; i++) {
            if (
                keccak256(abi.encodePacked(counterpartyVersion)) ==
                keccak256(abi.encodePacked(supportedVersions[i]))
            ) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, "Unsupported version");
        connectedChannels.push(channelId);
    }

    function onCloseIbcChannel(
        bytes32 channelId,
        string calldata counterpartyPortId,
        bytes32 counterpartyChannelId
    ) external {
        // logic to determin if the channel should be closed
        bool channelFound = false;
        for (uint i = 0; i < connectedChannels.length; i++) {
            if (connectedChannels[i] == channelId) {
                delete connectedChannels[i];
                channelFound = true;
                break;
            }
        }
        require(channelFound, "Channel not found");
    }
}
