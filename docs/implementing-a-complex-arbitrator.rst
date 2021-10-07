=================================
Implementing a Complex Arbitrator
=================================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

We will refactor ``SimpleCentralizedArbitrator`` to add appeal functionality and dynamic costs.

Recall ``SimpleCentralizedArbitrator``:

.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript

First, let's implement the appeal:

.. code-block:: javascript
  :emphasize-lines: 8,15,16,36,37,44-48,55-94

  pragma solidity ^0.5;

  import "../Arbitrator.sol";

  contract CentralizedArbitratorWithAppeal is Arbitrator {

      address public owner = msg.sender;
      uint constant appealWindow = 3 minutes;

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
          }));

          emit DisputeCreation(disputeID, IArbitrable(msg.sender));
      }

      function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
          Dispute storage dispute = disputes[_disputeID];
          if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealPeriodEnd)
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
          dispute.appealPeriodStart = block.timestamp;
          dispute.appealPeriodEnd = dispute.appealPeriodStart + appealWindow;
      }

      function executeRuling(uint _disputeID) public {
          Dispute storage dispute = disputes[_disputeID];
          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(block.timestamp >= dispute.appealPeriodEnd, "The dispute must be executed after its appeal period has ended.");

          dispute.status = DisputeStatus.Solved;
          dispute.arbitrated.rule(_disputeID, dispute.ruling);
      }

      function appeal(uint _disputeID, bytes memory _extraData) public payable {
          Dispute storage dispute = disputes[_disputeID];

          super.appeal(_disputeID, _extraData);

          require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
          require(block.timestamp < dispute.appealPeriodEnd, "The appeal must occur before the end of the appeal period.");

          dispute.status = DisputeStatus.Waiting;
      }

      function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
          Dispute storage dispute = disputes[_disputeID];

          return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }
  }



We first define ``appealWindow`` constant, which is the amount of time a dispute stays appealable.

To implement ``appealPeriod`` function of the ERC-792 interface, we define two additional variables in ``Dispute`` struct: ``appealPeriodStart`` and ``appealPeriodEnd``.

``DisputeStatus`` function is also updated to handle the case where a dispute has ``DisputeStatus.Appealable`` status, but the appeal window is closed, so actually it is ``DisputeStatus.Solved``.

The important change is we divided proxy ``rule`` function into two parts.

- ``giveRuling``: Gives ruling, but does not enforce it.
- ``executeRuling`` Enforces ruling, only after the appeal window is closed.

Before, there was no appeal functionality, so we didn't have to wait for appeal and ruling was enforced immediately after giving the ruling. Now we need to do them separately.

``appeal`` function checks whether the dispute is eligible for appeal and performs the appeal by setting ``status`` back to the default value, ``DisputeStatus.Waiting``.


Now let's revisit cost functions:


.. literalinclude:: ../contracts/examples/CentralizedArbitratorWithAppeal.sol
    :language: javascript
    :emphasize-lines: 9, 18, 24, 28, 31-33, 44, 90



We implemented a setter for arbitration cost and we made the appeal cost as exponentially increasing.
We achieved that by counting the number of appeals with ``appealCount`` variable, which gets increased each time ``appeal`` is executed.

This concludes our implementation of a centralized arbitrator with appeal functionality.
