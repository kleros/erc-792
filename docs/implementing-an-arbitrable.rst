==========================
Implementing an Arbitrable
==========================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

Consider a case where two party trades ether for goods. Payer wants to pay only if payee provides promised goods. So payer deposits payment amount into an escrow and if a dispute arise an arbitrator will resolve it.
For sake of simplicity, we won't implement appealing functionality.

Let's start:

.. code-block:: javascript

  pragma solidity ^0.5.8;

  import "../IArbitrable.sol";
  import "../Arbitrator.sol";

  contract SimpleEscrow is IArbitrable {
      address payable public payer = msg.sender;
      address payable public payee;
      uint public value;
      Arbitrator public arbitrator;
      uint constant public reclamationPeriod = 3 days;
      uint constant public arbitrationFeeDepositPeriod = 3 days;
      string public agreement;
      uint public createdAt;

      constructor(address payable _payee, Arbitrator _arbitrator, string memory _agreement) public payable {
          value = msg.value;
          payee = _payee;
          arbitrator = _arbitrator;
          agreement = _agreement;
          createdAt = now;
      }
  }


``payer`` deploys the contract depositing the payment amount and specifying ``payee`` address, ``arbitrator`` that is authorized to rule and ``agreement`` string. Notice that ``payer = msg.sender``.

There will be two scenarios:
 1. No dispute arises, ``payee`` withdraws the funds.
 2. ``payer`` reclaims funds by depositing arbitration fee...
      a. ``payee`` fails to deposit arbitration fee in ``arbitrationFeeDepositPeriod`` and ``payer`` wins by default. Arbitration fee deposit refunded.
      b. ``payee`` deposits arbitration fee in time. Dispute gets created. ``arbitrator`` rules. Winner gets the arbitration fee refunded.

We made ``reclamationPeriod`` and ``arbitrationFeeDepositPeriod`` constant for sake of simplicity, they could be set by ``payer`` in the constructor too.

Let's implement the first scenario:

.. code-block:: javascript
  :emphasize-lines: 16,17,26,27,28,29,30,31,32,33,34

  pragma solidity ^0.5.8;

  import "../IArbitrable.sol";
  import "../Arbitrator.sol";

  contract SimpleEscrow is IArbitrable {
      address payable public payer = msg.sender;
      address payable public payee;
      uint public value;
      Arbitrator public arbitrator;
      uint constant public reclamationPeriod = 3 days;
      uint constant public arbitrationFeeDepositPeriod = 3 days;
      string public agreement;
      uint public createdAt;

      bool public disputed;
      bool public resolved;

      constructor(address payable _payee, Arbitrator _arbitrator, string memory _agreement) public payable {
          value = msg.value;
          payee = _payee;
          arbitrator = _arbitrator;
          agreement = _agreement;
          createdAt = now;
      }

      function releaseFunds() public {
          require(now - createdAt > reclamationPeriod, "Payer still has time to reclaim.");
          require(!disputed, "There is a dispute.");
          require(!resolved, "Already resolved.");

          resolved = true;
          payee.send(value);
      }

  }

In ``releaseFunds`` function, first we do state checks, ``reclamationPeriod`` should be passed, there shouldn't be a dispute and funds shouldn't be released already.
If so, we update ``resolved`` and send the funds to ``payee``.

Moving forward to second scenario:

.. code-block:: javascript
  :emphasize-lines: 18,19,21,33,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71

  pragma solidity ^0.5.8;
  import "../IArbitrable.sol";
  import "../Arbitrator.sol";

  contract SimpleEscrow is IArbitrable {
      address payable public payer = msg.sender;
      address payable public payee;
      uint public value;
      Arbitrator public arbitrator;
      uint constant public reclamationPeriod = 3 days;
      uint constant public arbitrationFeeDepositPeriod = 3 days;
      string public agreement;
      uint public createdAt;

      bool public disputed;
      bool public resolved;

      bool public awaitingArbitrationFeeFromPayee;
      uint public reclaimedAt;

      enum RulingOptions {PayerWins, PayeeWins, Count}

      constructor(address payable _payee, Arbitrator _arbitrator, string memory _agreement) public payable {
          value = msg.value;
          payee = _payee;
          arbitrator = _arbitrator;
          agreement = _agreement;
          createdAt = now;
      }

      function releaseFunds() public {
          require(now - createdAt > reclamationPeriod, "Payer still has time to reclaim.");
          require(reclaimedAt == 0, "Payer reclaimed the funds.");
          require(!disputed, "There is a dispute.");
          require(!resolved, "Already resolved.");

          resolved = true;
          payee.send(value);
      }

      function reclaimFunds() public payable {
          require(!resolved, "Already resolved.");
          require(msg.sender == payer, "Only the payer can reclaim the funds.");

          if(awaitingArbitrationFeeFromPayee){
              require(now - reclaimedAt > arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
              payer.send(value);
              resolved = true;
          }
          else{
            require(msg.value == arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
            reclaimedAt = now;
            awaitingArbitrationFeeFromPayee = true;
          }
      }

      function depositArbitrationFeeForPayee() public payable {
          require(!resolved, "Already resolved.");
          require(!disputed, "There is a dispute.");
          require(reclaimedAt > 0, "Payer didn't reclaim, nothing to dispute.");
          arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
      }

      function rule(uint _disputeID, uint _ruling) public {
          require(msg.sender == arbitrator, "Only the arbitrator can execute this.");
          require(!resolved, "Already resolved");
          require(disputed, "There should be dispute to execute a ruling.");
          resolved = true;
          if(_ruling == uint(RulingOptions.PayeeWins)) payer.send(address(this).balance);
          else payee.send(address(this).balance);
          emit Ruling(arbitrator, _disputeID, _ruling);
      }
  }

``reclaimFunds`` function lets ``payer`` to reclaim their funds. After that we let ``payee`` to deposit arbitration fee to create a dispute for ``arbitrationFeeDepositPeriod``, otherwise ``payer`` can call ``reclaimFunds`` again to retrieve funds.
In case if ``payee`` deposits arbitration fee in time a *dispute* gets created and the contract awaits arbitrators decision.

Also we add an extra ``require`` in ``releaseFunds`` function to ensure funds can't be released if reclaimed.

We define enforcement of rulings in ``rule`` function. Whoever wins the dispute should get the funds and should get reimbursed for arbitration fee.
Recall that we took arbitration fee deposit from both sides and used one of them to pay for the arbitrator. Thus the balance of the contract is at least funds plus arbitration fee. Therefore we send ``address(this).balance`` to the winner. Lastly, we emit ``Ruling`` as required in the standard.


That's it! We implemented a very simple escrow using ERC-792.
