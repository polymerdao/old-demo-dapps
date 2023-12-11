//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../node_modules/@open-ibc/vibc-core-smart-contracts/contracts/Ibc.sol';
import '../node_modules/@open-ibc/vibc-core-smart-contracts/contracts/IbcReceiver.sol';

/**
 * @title IbcDispatcher
 * @author Polymer Labs
 * @notice IBC dispatcher interface is the Polymer Core Smart Contract that implements the core IBC protocol.
 */
interface IbcDispatcherNew {
    function closeIbcChannel(bytes32 channelId) external;

    function openIbcChannel(
        IbcReceiver portAddress,
        string calldata version,
        ChannelOrder ordering,
        bool feeEnabled,
        string[] calldata connectionHops,
        CounterParty calldata counterparty,
        Proof calldata proof
    ) external;

    function sendPacket(
        bytes32 channelId,
        bytes calldata payload,
        uint64 timeoutTimestamp,
        PacketFee calldata fee
    ) external payable;
}