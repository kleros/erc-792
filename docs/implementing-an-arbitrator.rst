==========================
Implementing an Arbitrator
==========================

.. note::
  This tutorial requires basic Solidity programming skills.

First we will implement a very simple arbitrator where single wallet gives rulings and there won't be any appeals.

Let's start by implementing cost functions:

.. code-block:: javascript

  pragma solidity ^0.5.8;
  import "../Arbitrator.sol";

  contract SimpleCentralizedArbitrator is Arbitrator {

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee){
          fee = 0.1 ether;
      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee){
          fee = 2^250 ether; // An unaffordable amount which practically avoids appeals.
      }
  }

We set arbitration fee to ``0.1 ether`` and appeal fee to an astronomic amount which can't be afforded.
So in practice, we disabled appealing. We did implement neither a dynamic cost nor a setter to update the cost. Instead we made it constant, for sake of simplicity of this tutorial.

Next, we need a data structure to keep track of disputes:

.. code-block:: javascript
  :emphasize-lines: 5,6,7,8,9,10,11,13

  pragma solidity ^0.5.8;
  import "../Arbitrator.sol";

  contract SimpleCentralizedArbitrator is Arbitrator {

      struct Dispute {
          Arbitrable arbitrated;
          uint choices;
          uint ruling;
          DisputeStatus status;
      }

      Dispute[] public disputes;

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee){
          fee = 0.1 ether;
      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee){
          fee = 2^250 ether; // An unaffordable amount which practically avoids appeals.
      }
  }

Each dispute belongs to an ``Arbitrable`` contract, so we have ``arbitrated`` field for it.
Each dispute has a number of ruling options: Like Party A wins and Party B wins. We can also use the option at index zero for abstain / refuse to arbitrate.
Each dispute will have a ruling, we will store it inside ``ruling`` field.
Finally, each dispute will have a status, and we store it inside ``status`` field.

Next, we can implement the function for creating disputes:

.. code-block:: javascript
  :emphasize-lines: 23,24,25,26,27,28,29,30,32,33

  pragma solidity ^0.5.8;
  import "../Arbitrator.sol";

  contract SimpleCentralizedArbitrator is Arbitrator {

      struct Dispute {
          Arbitrable arbitrated;
          uint choices;
          uint ruling;
          DisputeStatus status;
      }

      Dispute[] public disputes;

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee){
          fee = 0.1 ether;
      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee){
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
  }

Recall that ``createDispute`` function from abstract ``Arbitrator`` contract: ``function createDispute(uint _choices, bytes memory _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}``. We, first execute ``super.createDispute(_choices, _extraData)`` to apply ``requireArbitrationFee`` modifier. So if caller of ``createDispute`` doesn't pass required amount of ether with the call, function will revert. Then, we create the dispute by pushing a new element to the array: ``disputes.push( ... )``. ``push`` function returns resulting size of the array, so we can use the return value of ``disputes.push( ... ) -1`` as ``disputeID``. Finally, we emit ``DisputeCreation`` as required in the standard.

We also need to implement getters for ``status`` and ``ruling``:

.. code-block:: javascript
  :emphasize-lines: 35,36,37,39,40,41

  pragma solidity ^0.5.8;
  import "../Arbitrator.sol";

  contract SimpleCentralizedArbitrator is Arbitrator {

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
  }

Finally, we need a proxy function to call ``rule`` function of the ``Arbitrable`` contract. In this simple ``Arbitrator`` we will let one address to give rulings, the creator of the contract. So let's start by keeping track who created the contract:

.. code-block:: javascript
  :emphasize-lines: 3

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
  }

Then the proxy function:

.. code-block:: javascript
  :emphasize-lines: 45,46,47,48,59,50,51,52,53,54,55,56,57,58,59,60

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

First we check the caller address, we should only let the ``owner`` to execute this. Then we do sanity checks: Given ruling should be chosen among the ``choices`` and one should not be able to ``rule`` on an already solved dispute.
Then we update ``ruling`` and ``status`` values of the dispute. Then we pay arbitration fee to the arbitrator (``owner``). And finally, we call ``rule`` function of the ``arbitrated`` to enforce the ruling.

That's it, we have a working, very simple and centralized arbitrator!
