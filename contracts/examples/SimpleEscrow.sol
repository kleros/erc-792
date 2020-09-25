/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "../IArbitrable.sol";
import "../IArbitrator.sol";

contract SimpleEscrow is IArbitrable {
    address payable public payer = msg.sender;
    address payable public payee;
    uint256 public value;
    IArbitrator public arbitrator;
    string public agreement;
    uint256 public createdAt;
    uint256 public constant reclamationPeriod = 3 minutes;
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes;

    enum Status {Initial, Reclaimed, Disputed, Resolved}
    Status public status;

    uint256 public reclaimedAt;

    enum RulingOptions {RefusedToArbitrate, PayerWins, PayeeWins}
    uint256 constant numberOfRulingOptions = 2; // Notice that option 0 is reserved for RefusedToArbitrate.

    constructor(
        address payable _payee,
        IArbitrator _arbitrator,
        string memory _agreement
    ) payable {
        value = msg.value;
        payee = _payee;
        arbitrator = _arbitrator;
        agreement = _agreement;
        createdAt = block.timestamp;
    }

    function releaseFunds() public {
        require(status == Status.Initial, "Transaction is not in Initial state.");

        if (msg.sender != payer)
            require(block.timestamp - createdAt > reclamationPeriod, "Payer still has time to reclaim.");

        status = Status.Resolved;
        payee.send(value);
    }

    function reclaimFunds() public payable {
        require(
            status == Status.Initial || status == Status.Reclaimed,
            "Transaction is not in Initial or Reclaimed state."
        );
        require(msg.sender == payer, "Only the payer can reclaim the funds.");

        if (status == Status.Reclaimed) {
            require(
                block.timestamp - reclaimedAt > arbitrationFeeDepositPeriod,
                "Payee still has time to deposit arbitration fee."
            );
            payer.send(address(this).balance);
            status = Status.Resolved;
        } else {
            require(block.timestamp - createdAt <= reclamationPeriod, "Reclamation period ended.");
            require(
                msg.value == arbitrator.arbitrationCost(""),
                "Can't reclaim funds without depositing arbitration fee."
            );
            reclaimedAt = block.timestamp;
            status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        require(status == Status.Reclaimed, "Transaction is not in Reclaimed state.");
        arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, "");
        status = Status.Disputed;
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(status == Status.Disputed, "There should be dispute to execute a ruling.");
        require(_ruling <= numberOfRulingOptions, "Ruling out of bounds!");

        status = Status.Resolved;
        if (_ruling == uint256(RulingOptions.PayerWins)) payer.send(address(this).balance);
        else if (_ruling == uint256(RulingOptions.PayeeWins)) payee.send(address(this).balance);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    function remainingTimeToReclaim() public view returns (uint256) {
        if (status != Status.Initial) revert("Transaction is not in Initial state.");
        return
            (createdAt + reclamationPeriod - block.timestamp) > reclamationPeriod
                ? 0
                : (createdAt + reclamationPeriod - block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee() public view returns (uint256) {
        if (status != Status.Reclaimed) revert("Transaction is not in Reclaimed state.");
        return
            (reclaimedAt + arbitrationFeeDepositPeriod - block.timestamp) > arbitrationFeeDepositPeriod
                ? 0
                : (reclaimedAt + arbitrationFeeDepositPeriod - block.timestamp);
    }
}
