/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.9;

import "../IArbitrable.sol";
import "../IArbitrator.sol";
import "../erc-1497/IEvidence.sol";

contract SimpleEscrowWithERC1497 is IArbitrable, IEvidence {
    address payable public payer = payable(msg.sender);
    address payable public payee;
    uint256 public value;
    IArbitrator public arbitrator;
    uint256 public constant reclamationPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.

    uint256 public createdAt;
    uint256 public reclaimedAt;

    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    Status public status;

    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }
    uint256 constant numberOfRulingOptions = 2;

    uint256 constant metaevidenceID = 0;
    uint256 constant evidenceGroupID = 0;

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);
    error UnexistingDispute();

    constructor(
        address payable _payee,
        IArbitrator _arbitrator,
        string memory _metaevidence
    ) payable {
        value = msg.value;
        payee = _payee;
        arbitrator = _arbitrator;
        createdAt = block.timestamp;

        emit MetaEvidence(metaevidenceID, _metaevidence);
    }

    function releaseFunds() public {
        require(status == Status.Initial, "Transaction is not in Initial state.");

        if (msg.sender != payer && block.timestamp - createdAt <= reclamationPeriod) {
            revert ReleasedTooEarly();
        }

        status = Status.Resolved;
        payee.send(value);
    }

    function reclaimFunds() public payable {
        if (status != Status.Initial && status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        if (msg.sender != payer) {
            revert NotPayer();
        }

        if (status == Status.Reclaimed) {
            if (block.timestamp - reclaimedAt <= arbitrationFeeDepositPeriod) {
                revert PayeeDepositStillPending();
            }
            payer.send(address(this).balance);
            status = Status.Resolved;
        } else {
            if (block.timestamp - createdAt > reclamationPeriod) {
                revert ReclaimedTooLate();
            }
            uint256 requiredCost = arbitrator.arbitrationCost("");
            if (msg.value < requiredCost) {
                revert InsufficientPayment(msg.value, requiredCost);
            }
            reclaimedAt = block.timestamp;
            status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        if (status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        uint256 disputeID = arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, "");
        status = Status.Disputed;
        emit Dispute(arbitrator, disputeID, metaevidenceID, evidenceGroupID);
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        if (msg.sender != address(arbitrator)) {
            revert NotArbitrator();
        }
        if (status != Status.Disputed) {
            revert UnexistingDispute();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }

        status = Status.Resolved;
        if (_ruling == uint256(RulingOptions.PayerWins)) payer.send(address(this).balance);
        else payee.send(address(this).balance);
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

    function submitEvidence(string memory _evidence) public {
        if (status == Status.Resolved) {
            revert InvalidStatus();
        }
        if (msg.sender != payer && msg.sender != payee) {
            revert ThirdPartyNotAllowed();
        }
        emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
    }
}
