pragma solidity >=0.6;

import "../IArbitrator.sol";

contract SimpleCentralizedArbitrator is IArbitrator {

    address public owner = msg.sender;

    struct Dispute {
        IArbitrable arbitrated;
        uint choices;
        uint ruling;
        DisputeStatus status;
    }

    Dispute[] public disputes;

    function arbitrationCost(bytes memory _extraData) public view override returns(uint fee) {
        fee = 0.1 ether;
    }

    function appealCost(uint _disputeID, bytes memory _extraData) public view override returns(uint fee) {
        fee = 2**250; // An unaffordable amount which practically avoids appeals.
    }

    function createDispute(uint _choices, bytes memory _extraData) public payable override returns(uint disputeID) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");

        disputes.push(Dispute({
          arbitrated: IArbitrable(msg.sender),
          choices: _choices,
          ruling: uint(-1),
          status: DisputeStatus.Waiting
          }));

        disputeID = disputes.length -1;
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    function disputeStatus(uint _disputeID) public view override returns(DisputeStatus status) {
        status = disputes[_disputeID].status;
    }

    function currentRuling(uint _disputeID) public view override returns(uint ruling) {
        ruling = disputes[_disputeID].ruling;
    }

    function rule(uint _disputeID, uint _ruling) public {
        require(msg.sender == owner, "Only the owner of this contract can execute rule function.");

        Dispute storage dispute = disputes[_disputeID];

        require(_ruling <= dispute.choices, "Ruling out of bounds!");
        require(dispute.status == DisputeStatus.Waiting, "Dispute is not awaiting arbitration.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        msg.sender.send(arbitrationCost(""));
        dispute.arbitrated.rule(_disputeID, _ruling);
    }

    function appeal(uint _disputeID, bytes memory _extraData) public payable override {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover arbitration costs.");
    }

    function appealPeriod(uint _disputeID) public view override returns(uint start, uint end) {
        return (0,0);
    }
}
