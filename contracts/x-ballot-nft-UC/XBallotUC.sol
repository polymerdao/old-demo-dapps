//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../base/UniversalChanIbcApp.sol';

contract XBallotUC is UniversalChanIbcApp {

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

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Not chairperson.");
        _;
    }

    constructor(bytes32[] memory proposalNames, address _middleware) UniversalChanIbcApp(_middleware) {
        chairperson = msg.sender;
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
        // FOR TESTING ONLY
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
    
    // Utility functions

    function resetVoter(address voterAddr) external onlyChairperson {
        voters[voterAddr].ibcNFTMinted = false;
        voters[voterAddr].voted = false;
        voters[voterAddr].vote = 0;
        voters[voterAddr].weight = 0;
    }  

    /**
     * @dev Sends a packet with a greeting message over a specified channel.
     * @param destPortAddr The address of the destination application to be used in the port identifier.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     * @param voterAddress the address of the voter
     * @param recipient the address on the destination (Base) that will have NFT minted
     */

    function sendUniversalPacket(
        address destPortAddr,
        bytes32 channelId, 
        uint64 timeoutSeconds,
        address voterAddress,
        address recipient
        ) external {
        require(voters[voterAddress].ibcNFTMinted == false, "Already has a ProofOfVote NFT minted on counterparty");

        uint voteId = voters[voterAddress].vote;
        bytes memory payload = abi.encode(voterAddress, recipient, voteId);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(address(this)),
            payload,
            timeoutTimestamp
        );
    }

    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        require(false, "This function should not be called");

        return AckPacket(true, abi.encode("Error: This function should not be called"));
    }

    function onUniversalAcknowledgement(
            bytes32 channelId,
            UniversalPacket memory packet,
            AckPacket calldata ack
    ) external override onlyIbcMw {
        // verify packet's destPortAddr is the ack's first encoded address. assumes the packet's destPortAddr is the address of the contract that sent the packet
        // check onRecvUniversalPacket for the encoded ackpacket data
        require(ack.data.length >= 20, 'ack data too short');
        address ackSender = address(bytes20(ack.data[0:20]));
        require(IbcUtils.toAddress(packet.destPortAddr) == ackSender, 'ack address mismatch');
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        bytes memory usefulAckData = ack.data[20:];

        // decode the ack data, find the address of the voter the packet belongs to and set ibcNFTMinted true
        (address voterAddress, uint256 voteNFTId) = abi.decode(usefulAckData, (address, uint256));
        voters[voterAddress].ibcNFTMinted = true;
    }

    function onTimeoutUniversalPacket(
        bytes32 channelId, 
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // Timeouts not currently supported
    }
}
