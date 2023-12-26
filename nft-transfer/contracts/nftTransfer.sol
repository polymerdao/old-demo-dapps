// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./vibc-core/Ibc.sol";
import "./vibc-core/IbcReceiver.sol";
import "./vibc-core/IbcDispatcher.sol";

/**
 * @title mintAndTransfer
 * @dev can mint and NFT and transfer it to a destination chain via IBC
 */
contract nftTransfer is IbcReceiver, IbcReceiverBase, ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string private constant TOKEN_URI =
        "https://imgur.com/a/xRmS8hA";
    Counters.Counter private currentTokenId;
    mapping(uint256 => bool) private _lockedTokens;

    string[] public supportedVersions;
    bytes32[] public connectedChannels;

    AckPacket[] public ackPackets;
    IbcPacket[] public timeoutPackets;
    IbcPacket[] public recvedPackets;

    //DEBUGGER EVENTS
    event packetTest(bytes packetData);
    //DEBUGGER EVENTS

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTLocked(address indexed owner, uint256 indexed tokenId);
    event NFTUnlocked(address indexed owner, uint256 indexed tokenId);
    event AckPacketReceived(
        uint256 indexed tokenId,
        address destinationAddress,
        bytes packetData
    );
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
        IbcDispatcher _dispatcher,
        string memory nftName,
        string memory nftSymbol
    ) ERC721(nftName, nftSymbol) IbcReceiverBase(_dispatcher) {
        supportedVersions.push("1.0");
        supportedVersions.push("2.0");
    }

    function mintNFT(address recipient) public onlyOwner returns (uint256) {
        currentTokenId.increment();
        _safeMint(recipient, currentTokenId.current());
        emit NFTMinted(recipient, currentTokenId.current());
        return currentTokenId.current();
    }

    function lockNFT(uint256 tokenId) internal {
        _lockedTokens[tokenId] = true;
        emit NFTLocked(ownerOf(tokenId), tokenId);
    }

    function unlockNFT(uint256 tokenId) internal {
        _lockedTokens[tokenId] = false;
        emit NFTUnlocked(ownerOf(tokenId), tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return TOKEN_URI;
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
        string memory memo
    ) internal returns (bytes memory) {
        require(_lockedTokens[tokenId] == true, "This token is not locked");
        NonFungibleTokenPacketData
            memory packetData = NonFungibleTokenPacketData({
                classId: getClassId(tokenId),
                classUri: TOKEN_URI,
                classData: "",
                tokenIds: new string[](1),
                tokenUris: new string[](1),
                tokenData: new string[](1),
                sender: senderAddress,
                receiver: recipientAddress,
                memo: memo
            });
        packetData.tokenIds[0] = "5";//tokenId.toString();
        packetData.tokenUris[0] = tokenURI(tokenId);
        packetData.tokenData[0] = "The first ever cross chain Polymer NFT!";

        bytes memory payload = abi.encode(packetData);
        uint64 timeoutTimestamp = uint64(
            (block.timestamp + 36000) * 100000000
        );
        bytes32 channelId = connectedChannels[0];

        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
        return payload;
    }

    function initiateNFTTransfer(
        uint256 tokenId,
        address destinationAddress,
        string memory memo
    ) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        lockNFT(tokenId);
        bytes memory data = transferNFT(
            tokenId,
            msg.sender,
            destinationAddress,
            memo
        );
        emit NFTTransferred(msg.sender, tokenId, destinationAddress, data);
    }

    function getAllTokens() public view returns (uint256[] memory) {
        uint256 tokenCount = currentTokenId.current();
        uint256[] memory tokens = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = i + 1;
        }

        return tokens;
    }

    function getMyTokens() public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(msg.sender);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = currentTokenId.current();
            uint256 resultIndex = 0;

            for (uint256 tokenId = 1; tokenId <= totalTokens; tokenId++) {
                if (ownerOf(tokenId) == msg.sender) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // IBC Packet Callbacks

    function createChannel(
        bool feeEnabled,
        string[] calldata connectionHops,
        CounterParty calldata counterparty,
        Proof calldata proof
    ) external {
        dispatcher.openIbcChannel(
            IbcReceiver(address(this)),
            supportedVersions[0],
            ChannelOrder.UNORDERED,
            feeEnabled,
            connectionHops,
            counterparty,
            proof
        );
    }

    function onRecvPacket(
        IbcPacket calldata packet
    ) external returns (AckPacket memory ackPacket) {
                emit packetTest(packet.data);
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
        return AckPacket(true, '');//ackData
    }

    function onAcknowledgementPacket(
        IbcPacket calldata packet,
        AckPacket calldata ack
    ) external {
        ackPackets.push(ack);
        // decode the ack data and do something with it
        emit AckPacketReceived(
            stringToUint(abi.decode(ack.data, (string))),
            abi.decode(ack.data, (address)),
            packet.data
        );
    }

    function onTimeoutPacket(IbcPacket calldata packet) external {
        timeoutPackets.push(packet);
    }

    // IBC Channel Callbacks
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

    // Utility Functions
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
}
