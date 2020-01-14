pragma solidity >=0.6;

import "../IArbitrable.sol";
import "../IArbitrator.sol";
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
        IArbitrator arbitrator;
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

    function newTransaction(address payable _payee, IArbitrator _arbitrator, string memory _metaevidence, uint _reclamationPeriod, uint _arbitrationFeeDepositPeriod) public payable returns (uint txID){
        emit MetaEvidence(txs.length, _metaevidence);

        txs.push(TX({
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
          }));

        txID = txs.length;
    }

    function releaseFunds(uint _txID) public {
        TX storage transaction = txs[_txID];

        require(transaction.status == Status.Initial, "Transaction is not in Initial state.");
        if (msg.sender != transaction.payer)
          require(now - transaction.createdAt > transaction.reclamationPeriod, "Payer still has time to reclaim.");

        transaction.status = Status.Resolved;
        transaction.payee.send(transaction.value);
    }

    function reclaimFunds(uint _txID) public payable {
        TX storage transaction = txs[_txID];

        require(transaction.status == Status.Initial || transaction.status == Status.Reclaimed, "Transaction is not in Initial or Reclaimed state.");
        require(msg.sender == transaction.payer, "Only the payer can reclaim the funds.");

        if(transaction.status == Status.Reclaimed){
            require(now - transaction.reclaimedAt > transaction.arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
            transaction.payer.send(transaction.value + transaction.payerFeeDeposit);
            transaction.status = Status.Resolved;
        }
        else{
          require(now - transaction.createdAt <= transaction.reclamationPeriod, "Reclamation period ended.");
          require(msg.value >= transaction.arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
          transaction.payerFeeDeposit = msg.value;
          transaction.reclaimedAt = now;
          transaction.status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee(uint _txID) public payable {
        TX storage transaction = txs[_txID];

        require(transaction.status == Status.Reclaimed, "Transaction is not in Reclaimed state.");

        transaction.payeeFeeDeposit = msg.value;
        transaction.disputeID = transaction.arbitrator.createDispute.value(msg.value)(numberOfRulingOptions, "");
        transaction.status = Status.Disputed;
        disputeIDtoTXID[transaction.disputeID] = _txID;
        emit Dispute(transaction.arbitrator, transaction.disputeID, _txID, _txID);
    }

    function rule(uint _disputeID, uint _ruling) public override {
        uint txID = disputeIDtoTXID[_disputeID];
        TX storage transaction = txs[txID];

        require(msg.sender == address(transaction.arbitrator), "Only the arbitrator can execute this.");
        require(transaction.status == Status.Disputed, "There should be dispute to execute a ruling.");
        require(_ruling <= numberOfRulingOptions, "Ruling out of bounds!");

        transaction.status = Status.Resolved;

        if (_ruling == uint(RulingOptions.PayerWins)) transaction.payer.send(transaction.value + transaction.payerFeeDeposit);
        else transaction.payee.send(transaction.value + transaction.payeeFeeDeposit);
        emit Ruling(transaction.arbitrator, _disputeID, _ruling);
    }


    function submitEvidence(uint _txID, string memory _evidence) public {
        TX storage transaction = txs[_txID];

        require(transaction.status != Status.Resolved);
        require(msg.sender == transaction.payer || msg.sender == transaction.payee, "Third parties are not allowed to submit evidence.");

        emit Evidence(transaction.arbitrator, _txID, msg.sender, _evidence);
    }

    function remainingTimeToReclaim(uint _txID) public view returns (uint) {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) revert("Transaction is not in Initial state.");
        return (transaction.createdAt + transaction.reclamationPeriod - now) > transaction.reclamationPeriod ? 0 : (transaction.createdAt + transaction.reclamationPeriod - now);
    }

    function remainingTimeToDepositArbitrationFee(uint _txID) public view returns (uint) {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Reclaimed) revert("Transaction is not in Reclaimed state.");
        return (transaction.reclaimedAt + transaction.arbitrationFeeDepositPeriod - now) > transaction.arbitrationFeeDepositPeriod ? 0 : (transaction.reclaimedAt + transaction.arbitrationFeeDepositPeriod - now);
    }

}
