// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './vibc-core/Ibc.sol';
import './vibc-core/IbcReceiver.sol';
import './vibc-core/IbcDispatcher.sol';

/** 
 * @title IbcBallot
 * @dev Implements voting process along with vote delegation, 
 * and ability to send cross-chain instruction to mint NFT on counterparty
 */
contract IbcBallot is IbcReceiverBase, IbcReceiver {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted;    
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        // additional
        bool ibcNFTMinted; // if true, we've gotten an ack for the IBC packet and cannot attempt to send it again;  TODO: implement enum to account for pending state
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    /** 
     * 
     * IBC storage variables
     * 
     */ 

    // received ack packet as chain A
    AckPacket[] public ackPackets;
    // received timeout packet as chain A
    IbcPacket[] public timeoutPackets;
    bytes32[] public connectedChannels;

    string[] public supportedVersions;


    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32[] memory proposalNames, IbcDispatcher _dispatcher) IbcReceiverBase(_dispatcher) {
        chairperson = msg.sender;
        supportedVersions = ['1.0', '2.0']; //TODO: add setter to update

        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        // require(
        //     !voters[voter].voted,
        //     "The voter already voted."
        // );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        sender.weight = 1;
        require(sender.weight != 0, "Has no right to vote");
        // require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }


    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    /**
     * @param voterAddress the address of the voter
     * @param recipient the address on the destination (Base) that will have NFT minted
     */

    function sendMintNFTMsg(
        address voterAddress,
        address recipient
    ) external payable {
        require(voters[voterAddress].ibcNFTMinted == false, "Already has a ProofOfVote NFT minted on counterparty");

        uint voteId = voters[voterAddress].vote;
        bytes memory payload = abi.encode(voterAddress, recipient, voteId);

        // hard coding for demo
        bytes32 channelId = connectedChannels[0]; 
        uint64 timeoutTimestamp = uint64((block.timestamp + 36000) * 1000000000);

        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    // Utility functions

    function resetVoter(address voterAddr) external {
        voters[voterAddr].ibcNFTMinted = false;
        voters[voterAddr].voted = false;
        voters[voterAddr].vote = 0;
        voters[voterAddr].weight = 0;
    }

    function popConnectedChannels() external {
        require(msg.sender == chairperson, "You are not the chairperson");
        connectedChannels.pop();
    }

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

        dispatcher.openIbcChannel(
            IbcChannelReceiver(address(this)),
            supportedVersions[0],
            ChannelOrder.UNORDERED,
            feeEnabled,
            connectionHops,
            counterparty,
            proof
        );
    }    

    /** 
     * IBC Packet Callbacks
     */

    // @dev This function needs to be implemented to satisfy IbcReceiver interface, but should be a no-op
    function onRecvPacket(IbcPacket calldata packet) external onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        return AckPacket(false, abi.encodePacked('{ "account": "account", "reply": "function should not be triggered" }'));
    }

    function onAcknowledgementPacket(IbcPacket calldata packet, AckPacket calldata ack) external onlyIbcDispatcher {
        ackPackets.push(ack);

        // decode the ack data, find the address of the voter the packet belongs to and set ibcNFTMinted true
        (address voterAddress, uint256 voteNFTId) = abi.decode(ack.data, (address, uint256));
        voters[voterAddress].ibcNFTMinted = true;
    }

    function onTimeoutPacket(IbcPacket calldata packet) external onlyIbcDispatcher {
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