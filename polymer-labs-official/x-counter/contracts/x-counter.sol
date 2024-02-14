//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../vibc-core/contracts/Ibc.sol';
import '../vibc-core/contracts/IbcReceiver.sol';
import '../vibc-core/contracts/IbcDispatcher.sol';

contract Xcounter is IbcReceiverBase, IbcReceiver {
    // received packet as chain B
    IbcPacket[] public recvedPackets;
    // received ack packet as chain A
    AckPacket[] public ackPackets;
    // received timeout packet as chain A
    IbcPacket[] public timeoutPackets;

    struct ChannelMapping {
        bytes32 channelId;
        bytes32 cpChannelId;
    }
    
    // ChannelMapping array with the channel IDs of the connected channels
    ChannelMapping[] public connectedChannels;

    // add supported versions (format to be negotiated between apps)
    string[] supportedVersions = ['1.0'];

    uint64 public counter;
    mapping (uint64 => address) public counterMap;


    constructor(IbcDispatcher _dispatcher) IbcReceiverBase(_dispatcher) {}

    function updateDispatcher(IbcDispatcher _dispatcher) external onlyOwner {
        dispatcher = _dispatcher;
    }

    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function getConnectedChannels() external view returns (ChannelMapping[] memory) {
        return connectedChannels;
    }

    /**
     * @dev Sends a packet with a greeting message over a specified channel.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */

    function sendCounterUpdate( bytes32 channelId, uint64 timeoutSeconds) external {
        increment();
        bytes memory payload = abi.encode(msg.sender);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    function onRecvPacket(IbcPacket memory packet) external onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        recvedPackets.push(packet);
        address _caller = abi.decode(packet.data, (address));
        counterMap[packet.sequence] = _caller;

        increment();

        return AckPacket(true, abi.encode(counter));
    }

    function onAcknowledgementPacket(IbcPacket calldata packet, AckPacket calldata ack) external onlyIbcDispatcher {
        ackPackets.push(ack);
        
        (uint64 _counter) = abi.decode(ack.data, (uint64));
        
       if (_counter != counter) {
        resetCounter();
       }
    }

    function onTimeoutPacket(IbcPacket calldata packet) external onlyIbcDispatcher {
        timeoutPackets.push(packet);
        // do logic
    }
    
    /**
     * 
     * @param feeEnabled in production, you'll want to enable this to avoid spamming create channel calls (costly for relayers)
     * @param connectionHops 2 connection hops to connect to the destination via Polymer
     * @param counterparty the address of the destination chain contract you want to connect to
     * @param proof not implemented for now
     */
    function createChannel(
        string calldata version,
        uint8 ordering,
        bool feeEnabled, 
        string[] calldata connectionHops, 
        CounterParty calldata counterparty, 
        Proof calldata proof
        ) external {

        dispatcher.openIbcChannel(
            IbcChannelReceiver(address(this)),
            version,
            ChannelOrder(ordering),
            feeEnabled,
            connectionHops,
            counterparty,
            proof
        );
    } 

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
        for (uint256 i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(selectedVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');
        // if counterpartyVersion is not empty, then it must be the same foundVersion
        if (keccak256(abi.encodePacked(counterpartyVersion)) != keccak256(abi.encodePacked(''))) {
            require(
                keccak256(abi.encodePacked(counterpartyVersion)) == keccak256(abi.encodePacked(selectedVersion)),
                'Version mismatch'
            );
        }

        // do logic

        return selectedVersion;
    }

    function onConnectIbcChannel(
        bytes32 channelId,
        bytes32 counterpartyChannelId,
        string calldata counterpartyVersion
    ) external onlyIbcDispatcher {
        // ensure negotiated version is supported
        bool foundVersion = false;
        for (uint256 i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(counterpartyVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');

        // do logic

        ChannelMapping memory channelMapping = ChannelMapping({
            channelId: channelId,
            cpChannelId: counterpartyChannelId
        });
        connectedChannels.push(channelMapping);
    }

    function onCloseIbcChannel(
        bytes32 channelId,
        string calldata counterpartyPortId,
        bytes32 counterpartyChannelId
    ) external onlyIbcDispatcher {
        // logic to determin if the channel should be closed
        bool channelFound = false;
        for (uint256 i = 0; i < connectedChannels.length; i++) {
            if (connectedChannels[i].channelId == channelId) {
                delete connectedChannels[i];
                channelFound = true;
                break;
            }
        }
        require(channelFound, 'Channel not found');

        // do logic
    }

    /**
     * This func triggers channel closure from the dApp.
     * Func args can be arbitary, as long as dispatcher.closeIbcChannel is invoked propperly.
     */
    function triggerChannelClose(bytes32 channelId) external onlyOwner {
        dispatcher.closeIbcChannel(channelId);
    }
}
