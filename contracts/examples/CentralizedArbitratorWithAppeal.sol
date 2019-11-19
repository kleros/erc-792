pragma solidity ^0.5;

import "../IArbitrator.sol";

contract CentralizedArbitratorWithAppeal is IArbitrator {

    address public owner = msg.sender;
    uint constant appealWindow = 3 minutes;
    uint internal arbitrationFee = 1 finney;

    struct Dispute {
        IArbitrable arbitrated;
        uint choices;
        uint ruling;
        DisputeStatus status;
        uint appealPeriodStart;
        uint appealPeriodEnd;
        uint appealCount;
    }

    Dispute[] public disputes;

    function arbitrationCost(bytes memory _extraData) public view returns(uint fee) {
        fee = arbitrationFee;
    }

    function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee) {
        fee = arbitrationFee * (2 ** (disputes[_disputeID].appealCount));
    }

    function setArbitrationCost(uint _newCost) public {
        arbitrationFee = _newCost;
    }

    function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");

        disputeID = disputes.push(Dispute({
          arbitrated: IArbitrable(msg.sender),
          choices: _choices,
          ruling: uint(-1),
          status: DisputeStatus.Waiting,
          appealPeriodStart: 0,
          appealPeriodEnd: 0,
          appealCount: 0
          })) -1;

        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (disputes[_disputeID].status == DisputeStatus.Appealable && now >= dispute.appealPeriodEnd)
            return DisputeStatus.Solved;
        else
            return disputes[_disputeID].status;
    }

    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        ruling = disputes[_disputeID].ruling;
    }

    function giveRuling(uint _disputeID, uint _ruling) public {
        require(msg.sender == owner, "Only the owner of this contract can execute rule function.");

        Dispute storage dispute = disputes[_disputeID];

        require(_ruling <= dispute.choices, "Ruling out of bounds!");
        require(dispute.status == DisputeStatus.Waiting, "Dispute is not awaiting arbitration.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Appealable;
        dispute.appealPeriodStart = now;
        dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;

        emit AppealPossible(_disputeID, dispute.arbitrated);
    }

    function executeRuling(uint _disputeID) public {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(now > dispute.appealPeriodEnd, "The dispute must be executed after its appeal period has ended.");

        dispute.status = DisputeStatus.Solved;
        dispute.arbitrated.rule(_disputeID, dispute.ruling);
    }

    function appeal(uint _disputeID, bytes memory _extraData) public payable {
        Dispute storage dispute = disputes[_disputeID];
        dispute.appealCount++;

        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");

        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(now < dispute.appealPeriodEnd, "The appeal must occur before the end of the appeal period.");

        dispute.status = DisputeStatus.Waiting;

        emit AppealDecision(_disputeID, dispute.arbitrated);
    }

    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
        Dispute storage dispute = disputes[_disputeID];

        return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
  }
}
