pragma solidity ^0.5;

import "../IArbitrable.sol";
import "../Arbitrator.sol";

contract SimpleEscrow is IArbitrable {
    address payable public payer = msg.sender;
    address payable public payee;
    uint public value;
    Arbitrator public arbitrator;
    uint constant public reclamationPeriod = 3 minutes;
    uint constant public arbitrationFeeDepositPeriod = 3 minutes;
    string public agreement;

    uint public createdAt;
    uint public reclaimedAt;

    enum Status {Initial, Reclaimed, Disputed, Resolved}
    Status public status;

    enum RulingOptions {PayerWins, PayeeWins, Count}

    constructor(address payable _payee, Arbitrator _arbitrator, string memory _agreement) public payable {
        value = msg.value;
        payee = _payee;
        arbitrator = _arbitrator;
        agreement = _agreement;
        createdAt = now;
    }

    function releaseFunds() public {
      require(status == Status.Initial, "Transaction is not in initial status.");

      if(msg.sender != payer)
          require(now - createdAt > reclamationPeriod, "Payer still has time to reclaim.");

      status = Status.Resolved;
      payee.send(value);
    }

    function reclaimFunds() public payable {
        require(status == Status.Initial || status == Status.Reclaimed, "Status should be initial or reclaimed.");
        require(msg.sender == payer, "Only the payer can reclaim the funds.");

        if(status == Status.Reclaimed){
            require(now - reclaimedAt > arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
            payer.send(address(this).balance);
            status = Status.Resolved;
        }
        else{
          require(now - createdAt < reclamationPeriod, "Reclamation period ended.");
          require(msg.value == arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
          reclaimedAt = now;
          status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        require(status == Status.Reclaimed, "Payer didn't reclaim, nothing to dispute.");
        arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
        status = Status.Disputed;
    }

    function rule(uint _disputeID, uint _ruling) public {
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(status == Status.Disputed, "There should be dispute to execute a ruling.");
        status = Status.Resolved;
        if(_ruling == uint(RulingOptions.PayerWins)) payer.send(address(this).balance);
        else payee.send(address(this).balance);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    function remainingTimeToReclaim() public view returns (uint) {
        return createdAt + reclamationPeriod - now;
    }

    function remainingTimeToDepositArbitrationFee() public view returns (uint) {
        return reclaimedAt + arbitrationFeeDepositPeriod - now;
    }
}
