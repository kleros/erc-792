=================================
Implementing a Complex Arbitrator
=================================

We wills refactor ``SimpleCentralizedArbitrator`` to add appeal functionality and dynamic costs.

Recall ``SimpleCentralizedArbitrator``:

.. code-block:: javascript

  pragma solidity ^0.5.8;

  import "../Arbitrator.sol";

  contract SimpleCentralizedArbitrator is Arbitrator {

      address public owner = msg.sender;

      struct Dispute {
          IArbitrable arbitrated;
          uint choices;
          uint ruling;
          DisputeStatus status;
      }

      Dispute[] public disputes;

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee) {
          fee = 0.1 ether;
      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee) {
          fee = 2**250; // An unaffordable amount which practically avoids appeals.
      }

      function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID) {
          super.createDispute(_choices, _extraData);
          disputeID = disputes.push(Dispute({
            arbitrated: IArbitrable(msg.sender),
            choices: _choices,
            ruling: 0,
            status: DisputeStatus.Waiting
            })) -1;

          emit DisputeCreation(disputeID, IArbitrable(msg.sender));
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

First let's implement appeal:

.. code-block:: javascript
  :emphasize-lines: 8,15,16,36,37,43-49,55-94

  pragma solidity ^0.5.8;

  import "../Arbitrator.sol";

  contract CentralizedArbitratorWithAppeal is Arbitrator {

      address public owner = msg.sender;
      uint constant appealWindow = 3 days;

      struct Dispute {
          IArbitrable arbitrated;
          uint choices;
          uint ruling;
          DisputeStatus status;
          uint appealPeriodStart;
          uint appealPeriodEnd;
      }

      Dispute[] public disputes;

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee) {
          fee = 0.1 ether;
      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee) {
          fee = 2**250; // An unaffordable amount which practically avoids appeals.
      }

      function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID) {
          super.createDispute(_choices, _extraData);
          disputeID = disputes.push(Dispute({
            arbitrated: IArbitrable(msg.sender),
            choices: _choices,
            ruling: 0,
            status: DisputeStatus.Waiting,
            appealPeriodStart: 0,
            appealPeriodEnd: 0
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
          require(dispute.status != DisputeStatus.Solved, "Can't rule an already solved dispute!");

          dispute.ruling = _ruling;
          dispute.status = DisputeStatus.Appealable;
          dispute.appealPeriodStart = now;
          dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;
      }

      function executeRuling(uint _disputeID) public {
          Dispute storage dispute = disputes[_disputeID];
          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(now >= dispute.appealPeriodEnd, "The dispute must be executed after its appeal period has ended.");

          dispute.status = DisputeStatus.Solved;
          dispute.arbitrated.rule(_disputeID, dispute.ruling);
      }

      function appeal(uint _disputeID, bytes memory _extraData) public payable {
          Dispute storage dispute = disputes[_disputeID];

          super.appeal(_disputeID, _extraData);

          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(now < dispute.appealPeriodEnd, "The appeal must occur before the end of the appeal period.");

          dispute.status = DisputeStatus.Waiting;
      }

      function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
          Dispute storage dispute = disputes[_disputeID];

          return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }
  }


We first define ``appealWindow`` constant which is the amount of time a dispute stays appealable.

To implement ``appealPeriod`` function in the interface, we define two additional variables in ``Dispute`` struct: ``appealPeriodStart`` and ``appealPeriodEnd``.

``DisputeStatus`` function is also updated to handle the case where a dispute has ``DisputeStatus.Appealable`` status but appeal window is closed so actually it is ``DisputeStatus.Solved`` now.

The important change is we broke proxy ``rule`` function into two pieces.

- ``giveRuling``: Gives ruling, but do not enforce it.
- ``executeRuling`` Enforces ruling, only after appeal window is closed.

Before, there was no appeal functionality, so we didn't have to wait appeal and enforced the ruling immediately after giving the ruling. Now we need to do them separately.

``appeal`` function checks whether the dispute eligible for appeal and sets ``status`` to ``DisputeStatus.Waiting``.


Now let's revisit cost functions:

.. code-block:: javascript
  :emphasize-lines: 9, 18, 24, 28, 31-34, 44, 94

  pragma solidity ^0.5.8;

  import "../Arbitrator.sol";

  contract CentralizedArbitratorWithAppeal is Arbitrator {

      address public owner = msg.sender;
      uint constant appealWindow = 3 days;
      uint internal arbitrationFee;

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
          fee = arbitrationFee ** (disputes[_disputeID].appealCount +2);
      }

      function setArbitrationCost(uint _newCost) public {
          arbitrationFee = _newCost;
      }

      function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID) {
          super.createDispute(_choices, _extraData);
          disputeID = disputes.push(Dispute({
            arbitrated: IArbitrable(msg.sender),
            choices: _choices,
            ruling: 0,
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
          require(dispute.status != DisputeStatus.Solved, "Can't rule an already solved dispute!");

          dispute.ruling = _ruling;
          dispute.status = DisputeStatus.Appealable;
          dispute.appealPeriodStart = now;
          dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;
      }

      function executeRuling(uint _disputeID) public {
          Dispute storage dispute = disputes[_disputeID];
          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(now >= dispute.appealPeriodEnd, "The dispute must be executed after its appeal period has ended.");

          dispute.status = DisputeStatus.Solved;
          dispute.arbitrated.rule(_disputeID, dispute.ruling);
      }

      function appeal(uint _disputeID, bytes memory _extraData) public payable {
          Dispute storage dispute = disputes[_disputeID];

          super.appeal(_disputeID, _extraData);

          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(now < dispute.appealPeriodEnd, "The appeal must occur before the end of the appeal period.");

          dispute.status = DisputeStatus.Waiting;
          dispute.appealCount++;
      }

      function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
          Dispute storage dispute = disputes[_disputeID];

          return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }
  }

We implemented a setter for arbitration cost and we made appeal cost exponentiation of arbitration fee.
To implement this, we are counting number of appeals with ``appealCost`` variable, which gets increased each time ``appeal`` is executed.
