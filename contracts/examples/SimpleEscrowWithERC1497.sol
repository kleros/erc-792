pragma solidity ^0.5.8;

import "../IArbitrable.sol";
import "../Arbitrator.sol";
import "../erc-1497/IEvidence.sol";

contract SimpleEscrowWithERC1497 is IArbitrable, IEvidence {
    address payable public payer = msg.sender;
    address payable public payee;
    uint public value;
    Arbitrator public arbitrator;
    uint constant public reclamationPeriod = 3 days;
    uint constant public arbitrationFeeDepositPeriod = 3 days;
    uint public createdAt;

    bool public disputed;
    bool public resolved;

    bool public awaitingArbitrationFeeFromPayee;
    uint public reclaimedAt;


    enum RulingOptions {PayerWins, PayeeWins, Count}

    uint constant metaevidenceID = 0;
    uint constant evidenceGroupID = 0;

    constructor(address payable _payee, Arbitrator _arbitrator, string memory _metaevidence) public payable {
        value = msg.value;
        payee = _payee;
        arbitrator = _arbitrator;
        createdAt = now;

        emit MetaEvidence(metaevidenceID, _metaevidence);
    }

    function releaseFunds() public {
        require(now - createdAt > reclamationPeriod, "Payer still has time to reclaim.");
        require(!disputed, "There is a dispute.");
        require(!resolved, "Already resolved.");

        resolved = true;
        payee.send(value);
    }

    function reclaimFunds() public payable {
        require(!resolved, "Already resolved.");
        require(!disputed, "There is a dispute.");
        require(msg.sender == payer, "Only the payer can reclaim the funds.");

        if(awaitingArbitrationFeeFromPayee){
            require(now - reclaimedAt > arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
            payer.send(value);
            resolved = true;
        }
        else{
          require(msg.value == arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
          reclaimedAt = now;
          awaitingArbitrationFeeFromPayee = true;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        require(!resolved, "Already resolved.");
        require(!disputed, "There is a dispute.");
        require(reclaimedAt > 0, "Payer didn't reclaim, nothing to dispute.");
        uint disputeID = arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
        emit Dispute(arbitrator, disputeID, metaevidenceID, evidenceGroupID);
    }

    function rule(uint _disputeID, uint _ruling) public {
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(!resolved, "Already resolved");
        require(disputed, "There should be dispute to execute a ruling.");
        resolved = true;
        if(_ruling == uint(RulingOptions.PayeeWins)) payer.send(address(this).balance);
        else payee.send(address(this).balance);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    function submitEvidence(string memory _evidence) public {
        require(msg.sender == payer || msg.sender == payee, "Third parties are not allowed to submit evidence.");
        emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
    }
}
