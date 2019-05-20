pragma solidity ^0.5;

import "../IArbitrable.sol";
import "../Arbitrator.sol";
import "../erc-1497/IEvidence.sol";

contract Escrow is IArbitrable, IEvidence {

    enum RulingOptions {PayerWins, PayeeWins, Count}

    constructor() public {
    }

    struct TX {
        address payable payer;
        address payable payee;
        Arbitrator arbitrator;
        uint value;
        bool disputed;
        uint disputeID;
        bool resolved;
        bool awaitingArbitrationFeeFromPayee;
        uint createdAt;
        uint reclaimedAt;
        uint payerFeeDeposit;
        uint payeeFeeDeposit;
        uint reclamationPeriod;
        uint arbitrationFeeDepositPeriod;
    }

    TX[] public txs;
    mapping (uint => uint) disputeIDtoTXID;

    function newTransaction(address payable _payee, Arbitrator _arbitrator, string memory _metaevidence, uint _reclamationPeriod, uint _arbitrationFeeDepositPeriod) public payable returns (uint txID){
        emit MetaEvidence(txs.length, _metaevidence);

        return txs.push(TX({
            payer: msg.sender,
            payee: _payee,
            arbitrator: _arbitrator,
            value: msg.value,
            disputed: false,
            disputeID: 0,
            resolved: false,
            awaitingArbitrationFeeFromPayee: false,
            createdAt: now,
            reclaimedAt: 0,
            payerFeeDeposit: 0,
            payeeFeeDeposit: 0,
            reclamationPeriod: _reclamationPeriod,
            arbitrationFeeDepositPeriod: _arbitrationFeeDepositPeriod
          })) -1;
    }

    function releaseFunds(uint _txID) public {
        TX storage tx = txs[_txID];

        require(!tx.resolved, "Already resolved.");
        require(tx.reclaimedAt == 0, "Payer reclaimed the funds.");
        require(now - tx.createdAt > tx.reclamationPeriod, "Payer still has time to reclaim.");

        tx.resolved = true;
        tx.payee.send(tx.value);
    }

    function reclaimFunds(uint _txID) public payable {
        TX storage tx = txs[_txID];

        require(!tx.resolved, "Already resolved.");
        require(!tx.disputed, "There is a dispute.");
        require(msg.sender == tx.payer, "Only the payer can reclaim the funds.");

        if(tx.awaitingArbitrationFeeFromPayee){
            require(now - tx.reclaimedAt > tx.arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
            tx.payer.send(tx.value + tx.payerFeeDeposit);
            tx.resolved = true;
        }
        else{
          require(msg.value == tx.arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
          tx.reclaimedAt = now;
          tx.awaitingArbitrationFeeFromPayee = true;
        }
    }

    function depositArbitrationFeeForPayee(uint _txID) public payable {
        TX storage tx = txs[_txID];


        require(!tx.resolved, "Already resolved.");
        require(!tx.disputed, "There is a dispute.");
        require(tx.reclaimedAt > 0, "Payer didn't reclaim, nothing to dispute.");
        tx.disputeID = tx.arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
        tx.disputed = true;
        disputeIDtoTXID[tx.disputeID] = _txID;
        emit Dispute(tx.arbitrator, tx.disputeID, _txID, _txID);
    }

    function rule(uint _disputeID, uint _ruling) public {
        uint txID = disputeIDtoTXID[_disputeID];
        TX storage tx = txs[txID];

        require(msg.sender == address(tx.arbitrator), "Only the arbitrator can execute this.");
        require(!tx.resolved, "Already resolved");
        require(tx.disputed, "There should be dispute to execute a ruling.");

        tx.resolved = true;

        if(_ruling == uint(RulingOptions.PayerWins)) tx.payer.send(tx.value + tx.payerFeeDeposit);
        else tx.payee.send(tx.value + tx.payeeFeeDeposit);
        emit Ruling(tx.arbitrator, _disputeID, _ruling);
    }


    function submitEvidence(uint _txID, string memory _evidence) public {
        TX storage tx = txs[_txID];

        require(!tx.resolved);
        require(msg.sender == tx.payer || msg.sender == tx.payee, "Third parties are not allowed to submit evidence.");

        emit Evidence(tx.arbitrator, _txID, msg.sender, _evidence);
    }

}
