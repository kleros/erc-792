=================================
Implementing a Complex Arbitrable
=================================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

Let's implement a full-fledged escrow this time, expanding ``SimpleEscrowWithERC1497`` contract we implemented earlier. We will call it just ``Escrow`` this time.

Recall ``SimpleEscrowWithERC1497``:

.. code-block:: javascript

  pragma solidity ^0.5.8;

  import "../IArbitrable.sol";
  import "../Arbitrator.sol";
  import "../erc-1497/IEvidence.sol";

  contract SimpleEscrowWithERC1497 is IArbitrable, IEvidence {
      address payable public payer = msg.sender;
      address payable public payee;
      uint public value;
      Arbitrator public arbitrator;
      uint constant public reclamationPeriod = 3 minutes;
      uint constant public arbitrationFeeDepositPeriod = 3 minutes;
      uint public createdAt;

      bool public disputed;
      bool public resolved;

      bool public awaitingArbitrationFeeFromPayee;
      uint public reclaimedAt;


      enum RulingOptions {PayerWins, PayeeWins, Count}

      uint constant metaevidenceID = 0;
      uint constant evidenceGroupID = 0;

      constructor(address payable _payee, Arbitrator _arbitrator, string memory _metaevidence) public payable {
          value = msg.value;
          payee = _payee;
          arbitrator = _arbitrator;
          createdAt = now;

          emit MetaEvidence(metaevidenceID, _metaevidence);
      }

      function releaseFunds() public {
          require(!resolved, "Already resolved.");
          require(reclaimedAt == 0, "Payer reclaimed the funds.");
          require(now - createdAt > reclamationPeriod, "Payer still has time to reclaim.");

          resolved = true;
          payee.send(value);
      }

      function reclaimFunds() public payable {
          require(!resolved, "Already resolved.");
          require(!disputed, "There is a dispute.");
          require(msg.sender == payer, "Only the payer can reclaim the funds.");

          if(awaitingArbitrationFeeFromPayee){
              require(now - reclaimedAt > arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
              payer.send(address(this).balance);
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
          uint disputeID = arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
          disputed = true;
          emit Dispute(arbitrator, disputeID, metaevidenceID, evidenceGroupID);
      }

      function rule(uint _disputeID, uint _ruling) public {
          require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
          require(!resolved, "Already resolved");
          require(disputed, "There should be dispute to execute a ruling.");
          resolved = true;
          if(_ruling == uint(RulingOptions.PayerWins)) payer.send(address(this).balance);
          else payee.send(address(this).balance);
          emit Ruling(arbitrator, _disputeID, _ruling);
      }

      function submitEvidence(string memory _evidence) public {
          require(msg.sender == payer || msg.sender == payee, "Third parties are not allowed to submit evidence.");
          emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
      }
  }


Payer needs to deploy a contract for each transaction, but contract deployment is expensive.
Instead we could use the same contract for multiple transactions between arbitrary parties with arbitrary arbitrators.

Let's separate contract deployment and transaction creation:

  .. code-block:: javascript
    :emphasize-lines: 10-124

    pragma solidity ^0.5.8;

    import "../IArbitrable.sol";
    import "../Arbitrator.sol";
    import "../erc-1497/IEvidence.sol";

    contract Escrow is IArbitrable, IEvidence {

        enum RulingOptions {PayerWins, PayeeWins, Count}

        constructor() public {
        }

        struct TX {
            address payable payer;
            address payable payee;
            Arbitrator arbitrator;
            uint value;
            bool disputed;
            uint disputeID;
            bool resolved;
            bool awaitingArbitrationFeeFromPayee;
            uint createdAt;
            uint reclaimedAt;
            uint payerFeeDeposit;
            uint payeeFeeDeposit;
            uint reclamationPeriod;
            uint arbitrationFeeDepositPeriod;
        }

        TX[] public txs;
        mapping (uint => uint) disputeIDtoTXID;

        function newTransaction(address payable _payee, Arbitrator _arbitrator, string memory _metaevidence, uint _reclamationPeriod, uint _arbitrationFeeDepositPeriod) public payable returns (uint txID){
            emit MetaEvidence(txs.length, _metaevidence);

            return txs.push(TX({
                payer: msg.sender,
                payee: _payee,
                arbitrator: _arbitrator,
                value: msg.value,
                disputed: false,
                disputeID: 0,
                resolved: false,
                awaitingArbitrationFeeFromPayee: false,
                createdAt: now,
                reclaimedAt: 0,
                payerFeeDeposit: 0,
                payeeFeeDeposit: 0,
                reclamationPeriod: _reclamationPeriod,
                arbitrationFeeDepositPeriod: _arbitrationFeeDepositPeriod
              })) -1;
        }

        function releaseFunds(uint _txID) public {
            TX storage tx = txs[_txID];

            require(!tx.resolved, "Already resolved.");
            require(tx.reclaimedAt == 0, "Payer reclaimed the funds.");
            require(now - tx.createdAt > tx.reclamationPeriod, "Payer still has time to reclaim.");

            tx.resolved = true;
            tx.payee.send(tx.value);
        }

        function reclaimFunds(uint _txID) public payable {
            TX storage tx = txs[_txID];

            require(!tx.resolved, "Already resolved.");
            require(!tx.disputed, "There is a dispute.");
            require(msg.sender == tx.payer, "Only the payer can reclaim the funds.");

            if(tx.awaitingArbitrationFeeFromPayee){
                require(now - tx.reclaimedAt > tx.arbitrationFeeDepositPeriod, "Payee still has time to deposit arbitration fee.");
                tx.payer.send(tx.value + tx.payerFeeDeposit);
                tx.resolved = true;
            }
            else{
              require(msg.value == tx.arbitrator.arbitrationCost(""), "Can't reclaim funds without depositing arbitration fee.");
              tx.reclaimedAt = now;
              tx.awaitingArbitrationFeeFromPayee = true;
            }
        }

        function depositArbitrationFeeForPayee(uint _txID) public payable {
            TX storage tx = txs[_txID];


            require(!tx.resolved, "Already resolved.");
            require(!tx.disputed, "There is a dispute.");
            require(tx.reclaimedAt > 0, "Payer didn't reclaim, nothing to dispute.");
            tx.disputeID = tx.arbitrator.createDispute.value(msg.value)(uint(RulingOptions.Count), "");
            tx.disputed = true;
            disputeIDtoTXID[tx.disputeID] = _txID;
            emit Dispute(tx.arbitrator, tx.disputeID, _txID, _txID);
        }

        function rule(uint _disputeID, uint _ruling) public {
            uint txID = disputeIDtoTXID[_disputeID];
            TX storage tx = txs[txID];

            require(msg.sender == address(tx.arbitrator), "Only the arbitrator can execute this.");
            require(!tx.resolved, "Already resolved");
            require(tx.disputed, "There should be dispute to execute a ruling.");

            tx.resolved = true;

            if(_ruling == uint(RulingOptions.PayerWins)) tx.payer.send(tx.value + tx.payerFeeDeposit);
            else tx.payee.send(tx.value + tx.payeeFeeDeposit);
            emit Ruling(tx.arbitrator, _disputeID, _ruling);
        }


        function submitEvidence(uint _txID, string memory _evidence) public {
            TX storage tx = txs[_txID];

            require(!tx.resolved);
            require(msg.sender == tx.payer || msg.sender == tx.payee, "Third parties are not allowed to submit evidence.");

            emit Evidence(tx.arbitrator, _txID, msg.sender, _evidence);
        }

    }


We first start by removing global state variables and defining ``TX`` struct. Each instance of this struct will represent a transaction thus will have transaction specific variables instead of globals.
We will store transactions inside ``txs`` array. And will create new transactions via ``newTransaction`` function.

``newTransaction`` function simply takes transaction specific information and push a ``TX`` into ``txs``. This ``txs`` array is append-only, we will never remove any item.
Having this, we will uniquely identify each transaction by their index in the array.

Next, we update all the functions with transaction specific variables instead of globals. Changes are merely adding ``tx.`` prefixes in front of expressions. Except we don't ``send(address(this).balance)`` now as the contract balance includes all the funds.
