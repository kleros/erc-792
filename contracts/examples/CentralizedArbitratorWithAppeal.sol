/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "../IArbitrator.sol";

contract CentralizedArbitratorWithAppeal is IArbitrator {
    address public owner = msg.sender;
    uint256 constant appealWindow = 3 minutes;
    uint256 internal arbitrationFee = 1e15;

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

    function arbitrationCost(bytes memory _extraData) public override view returns (uint256) {
        return arbitrationFee;
    }

    function appealCost(uint256 _disputeID, bytes memory _extraData) public override view returns (uint256) {
        return arbitrationFee * (2**(disputes[_disputeID].appealCount));
    }

    function setArbitrationCost(uint256 _newCost) public {
        arbitrationFee = _newCost;
    }

    function createDispute(uint256 _choices, bytes memory _extraData)
        public
        override
        payable
        returns (uint256 disputeID)
    {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");

        disputes.push(
            Dispute({
                arbitrated: IArbitrable(msg.sender),
                choices: _choices,
                ruling: uint256(-1),
                status: DisputeStatus.Waiting,
                appealPeriodStart: 0,
                appealPeriodEnd: 0,
                appealCount: 0
            })
        );

        emit DisputeCreation(disputeID, IArbitrable(msg.sender));

        disputeID = disputes.length;
    }

    function disputeStatus(uint256 _disputeID) public override view returns (DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealPeriodEnd)
            return DisputeStatus.Solved;
        else return disputes[_disputeID].status;
    }

    function currentRuling(uint256 _disputeID) public override view returns (uint256 ruling) {
        ruling = disputes[_disputeID].ruling;
    }

    function giveRuling(uint256 _disputeID, uint256 _ruling) public {
        require(msg.sender == owner, "Only the owner of this contract can execute rule function.");

        Dispute storage dispute = disputes[_disputeID];

        require(_ruling <= dispute.choices, "Ruling out of bounds!");
        require(dispute.status == DisputeStatus.Waiting, "Dispute is not awaiting arbitration.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Appealable;
        dispute.appealPeriodStart = block.timestamp;
        dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;

        emit AppealPossible(_disputeID, dispute.arbitrated);
    }

    function executeRuling(uint256 _disputeID) public {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(
            block.timestamp > dispute.appealPeriodEnd,
            "The dispute must be executed after its appeal period has ended."
        );

        dispute.status = DisputeStatus.Solved;
        dispute.arbitrated.rule(_disputeID, dispute.ruling);
    }

    function appeal(uint256 _disputeID, bytes memory _extraData) public override payable {
        Dispute storage dispute = disputes[_disputeID];
        dispute.appealCount++;

        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");

        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(
            block.timestamp < dispute.appealPeriodEnd,
            "The appeal must occur before the end of the appeal period."
        );

        dispute.status = DisputeStatus.Waiting;

        emit AppealDecision(_disputeID, dispute.arbitrated);
    }

    function appealPeriod(uint256 _disputeID) public override view returns (uint256 start, uint256 end) {
        Dispute storage dispute = disputes[_disputeID];

        return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }
}
