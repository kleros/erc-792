pragma solidity ^0.5;

import "../IArbitrable.sol";
import "../Arbitrator.sol";
import "../erc-1497/IEvidence.sol";

contract Escrow is IArbitrable, IEvidence {

    enum Status {Initial, Reclaimed, Disputed, Resolved}
    enum RulingOptions {RefusedToArbitrate, PayerWins, PayeeWins}
    uint constant numberOfRulingOptions = 2;

    constructor() public {
    }

    struct TX {
        address payable payer;
        address payable payee;
        Arbitrator arbitrator;
        Status status;
        uint value;
        uint disputeID;
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
            status: Status.Initial,
            value: msg.value,
            disputeID: 0,
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

        require(tx.status == Status.Initial, "Transaction is not in Initial state.");
        if (msg.sender != tx.payer)
          require(now - tx.createdAt > tx.reclamationPeriod, "Payer still has time to reclaim.");

        tx.status = Status.Resolved;
        tx.payee.send(tx.value);
    }

    function reclaimFunds(uint _txID) public payable {
        TX storage tx = txs[_txID];

        require(tx.status == Status.Initial || tx.status == Status.Reclaimed, "Transaction is not in Initial or Reclaimed state.");
        require(msg.sender == tx.payer, "Only the payer can reclaim the funds.");

        if(tx.status == Status.Reclaimed){
            require(now - tx.reclaimedAt > tx.arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
            tx.payer.send(tx.value + tx.payerFeeDeposit);
            tx.status = Status.Resolved;
        }
        else{
          require(now - tx.createdAt <= tx.reclamationPeriod, "Reclamation period ended.");
          require(msg.value == tx.arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
          tx.reclaimedAt = now;
          tx.status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee(uint _txID) public payable {
        TX storage tx = txs[_txID];

        require(tx.status == Status.Reclaimed, "Transaction is not in Reclaimed state.");

        tx.disputeID = tx.arbitrator.createDispute.value(msg.value)(numberOfRulingOptions, "");
        tx.status = Status.Disputed;
        disputeIDtoTXID[tx.disputeID] = _txID;
        emit Dispute(tx.arbitrator, tx.disputeID, _txID, _txID);
    }

    function rule(uint _disputeID, uint _ruling) public {
        uint txID = disputeIDtoTXID[_disputeID];
        TX storage tx = txs[txID];

        require(msg.sender == address(tx.arbitrator), "Only the arbitrator can execute this.");
        require(tx.status == Status.Disputed, "There should be dispute to execute a ruling.");
        require(_ruling <= numberOfRulingOptions, "Ruling out of bounds!");

        tx.status = Status.Resolved;

        if (_ruling == uint(RulingOptions.PayerWins)) tx.payer.send(tx.value + tx.payerFeeDeposit);
        else tx.payee.send(tx.value + tx.payeeFeeDeposit);
        emit Ruling(tx.arbitrator, _disputeID, _ruling);
    }


    function submitEvidence(uint _txID, string memory _evidence) public {
        TX storage tx = txs[_txID];

        require(tx.status != Status.Resolved);
        require(msg.sender == tx.payer || msg.sender == tx.payee, "Third parties are not allowed to submit evidence.");

        emit Evidence(tx.arbitrator, _txID, msg.sender, _evidence);
    }

    function remainingTimeToReclaim(uint _txID) public view returns (uint) {
        TX storage tx = txs[_txID];

        if (tx.status != Status.Initial) revert("Transaction is not in Initial state.");
        return (tx.createdAt + tx.reclamationPeriod - now) > tx.reclamationPeriod ? 0 : (tx.createdAt + tx.reclamationPeriod - now);
    }

    function remainingTimeToDepositArbitrationFee(uint _txID) public view returns (uint) {
        TX storage tx = txs[_txID];

        if (tx.status != Status.Reclaimed) revert("Transaction is not in Reclaimed state.");
        return (tx.reclaimedAt + tx.arbitrationFeeDepositPeriod - now) > tx.arbitrationFeeDepositPeriod ? 0 : (tx.reclaimedAt + tx.arbitrationFeeDepositPeriod - now);
    }

}
