/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.9;

import "../IArbitrator.sol";

contract CentralizedArbitratorWithAppeal is IArbitrator {
    address public owner = msg.sender;
    uint256 constant appealWindow = 3 minutes;
    uint256 internal arbitrationFee = 1e15;

    error NotOwner();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);
    error InvalidStatus(DisputeStatus _current, DisputeStatus _expected);
    error BeforeAppealPeriodEnd(uint256 _currentTime, uint256 _appealPeriodEnd);
    error AfterAppealPeriodEnd(uint256 _currentTime, uint256 _appealPeriodEnd);

    struct Dispute {
        IArbitrable arbitrated;
        uint256 choices;
        uint256 ruling;
        DisputeStatus status;
        uint256 appealPeriodStart;
        uint256 appealPeriodEnd;
        uint256 appealCount;
    }

    Dispute[] public disputes;

    function arbitrationCost(bytes memory _extraData) public view override returns (uint256) {
        return arbitrationFee;
    }

    function appealCost(uint256 _disputeID, bytes memory _extraData) public view override returns (uint256) {
        return arbitrationFee * (2**(disputes[_disputeID].appealCount));
    }

    function setArbitrationCost(uint256 _newCost) public {
        arbitrationFee = _newCost;
    }

    function createDispute(uint256 _choices, bytes memory _extraData)
        public
        payable
        override
        returns (uint256 disputeID)
    {
        uint256 requiredAmount = arbitrationCost(_extraData);
        if (msg.value > requiredAmount) {
            revert InsufficientPayment(msg.value, requiredAmount);
        }

        disputes.push(
            Dispute({
                arbitrated: IArbitrable(msg.sender),
                choices: _choices,
                ruling: 0,
                status: DisputeStatus.Waiting,
                appealPeriodStart: 0,
                appealPeriodEnd: 0,
                appealCount: 0
            })
        );

        disputeID = disputes.length - 1;
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    function disputeStatus(uint256 _disputeID) public view override returns (DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealPeriodEnd)
            return DisputeStatus.Solved;
        else return disputes[_disputeID].status;
    }

    function currentRuling(uint256 _disputeID) public view override returns (uint256 ruling) {
        ruling = disputes[_disputeID].ruling;
    }

    function giveRuling(uint256 _disputeID, uint256 _ruling) public {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        Dispute storage dispute = disputes[_disputeID];

        if (_ruling > dispute.choices) {
            revert InvalidRuling(_ruling, dispute.choices);
        }
        if (dispute.status != DisputeStatus.Waiting) {
            revert InvalidStatus(dispute.status, DisputeStatus.Waiting);
        }

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Appealable;
        dispute.appealPeriodStart = block.timestamp;
        dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;

        emit AppealPossible(_disputeID, dispute.arbitrated);
    }

    function executeRuling(uint256 _disputeID) public {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.status != DisputeStatus.Appealable) {
            revert InvalidStatus(dispute.status, DisputeStatus.Appealable);
        }

        if (block.timestamp <= dispute.appealPeriodEnd) {
            revert BeforeAppealPeriodEnd(block.timestamp, dispute.appealPeriodEnd);
        }

        dispute.status = DisputeStatus.Solved;
        dispute.arbitrated.rule(_disputeID, dispute.ruling);
    }

    function appeal(uint256 _disputeID, bytes memory _extraData) public payable override {
        Dispute storage dispute = disputes[_disputeID];
        dispute.appealCount++;

        uint256 requiredAmount = appealCost(_disputeID, _extraData);
        if (msg.value < requiredAmount) {
            revert InsufficientPayment(msg.value, requiredAmount);
        }

        if (dispute.status != DisputeStatus.Appealable) {
            revert InvalidStatus(dispute.status, DisputeStatus.Appealable);
        }

        if (block.timestamp > dispute.appealPeriodEnd) {
            revert AfterAppealPeriodEnd(block.timestamp, dispute.appealPeriodEnd);
        }

        dispute.status = DisputeStatus.Waiting;

        emit AppealDecision(_disputeID, dispute.arbitrated);
    }

    function appealPeriod(uint256 _disputeID) public view override returns (uint256 start, uint256 end) {
        Dispute storage dispute = disputes[_disputeID];

        return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }
}
