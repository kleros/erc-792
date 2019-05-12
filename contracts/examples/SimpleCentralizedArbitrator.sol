pragma solidity ^0.5.8;
import "../Arbitrator.sol";

contract SimpleCentralizedArbitrator is Arbitrator {

    address public owner = msg.sender;

    struct Dispute {
        Arbitrable arbitrated;
        uint choices;
        uint ruling;
        DisputeStatus status;
    }

    Dispute[] public disputes;

    function arbitrationCost(bytes memory _extraData) public view returns(uint fee) {
        fee = 0.1 ether;
    }

    function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee) {
        fee = 2^250 ether; // An unaffordable amount which practically avoids appeals.
    }

    function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID) {
        super.createDispute(_choices, _extraData);
        disputeID = disputes.push(Dispute({
          arbitrated: Arbitrable(msg.sender),
          choices: _choices,
          ruling: 0,
          status: DisputeStatus.Waiting
          })) -1;

        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    }

    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        status = disputes[_disputeID].status;
    }

    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        ruling = disputes[_disputeID].ruling;
    }

    function rule(uint _disputeID, uint _ruling) public {
        require(msg.sender == owner, "Only the owner of this contract can execute rule function.");

        Dispute storage dispute = disputes[_disputeID];

        require(_ruling <= dispute.choices, "Ruling out of bounds!");
        require(dispute.status != DisputeStatus.Solved, "Can't rule an already solved dispute!");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        msg.sender.send(arbitrationCost(""));
        dispute.arbitrated.rule(_disputeID, _ruling);
    }
}
