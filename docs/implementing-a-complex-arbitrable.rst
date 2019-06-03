=================================
Implementing a Complex Arbitrable
=================================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

Let's implement a full-fledged escrow this time, extending ``SimpleEscrowWithERC1497`` contract we implemented earlier. We will call it just ``Escrow`` this time.

Recall ``SimpleEscrowWithERC1497``:

.. literalinclude:: ../contracts/examples/SimpleEscrowWithERC1497.sol
    :language: javascript


The payer needs to deploy a contract for each transaction, but contract deployment is expensive.
Instead, we could use the same contract for multiple transactions between arbitrary parties with arbitrary arbitrators.

Let's separate contract deployment and transaction creation:

.. literalinclude:: ../contracts/examples/Escrow.sol
    :language: javascript
    :emphasize-lines: 9-


We first start by removing the global state variables and defining ``TX`` struct. Each instance of this struct will represent a transaction, thus will have transaction-specific variables instead of globals.
We stored transactions inside ``txs`` array. We also created new transactions via ``newTransaction`` function.

``newTransaction`` function simply takes transaction-specific information and pushes a ``TX`` into ``txs``. This ``txs`` array is append-only, we will never remove any item.
By implementing this, we can uniquely identify each transaction by their index in the array.

Next, we updated all the functions with transaction-specific variables instead of globals. Changes are merely adding ``tx.`` prefixes in front of expressions.

We also stored fee deposits for each party, as the smart contract now has balances for multiple transactions that we can't ``send(address(this).balance)``.
Instead, we used ``tx.payer.send(tx.value + tx.payerFeeDeposit);`` if ``payer`` wins and ``tx.payee.send(tx.value + tx.payeeFeeDeposit);`` if ``payee`` wins.

Notice that ``rule`` function has no transaction ID parameter, but we need to obtain transaction details of given dispute. We achieved this by storing the transaction ID for respective dispute ID as ``disputeIDtoTXID``.
Just after dispute creation (inside ``depositArbitrationFeeForPayee``), we store this relation with ``disputeIDtoTXID[tx.disputeID] = _txID;`` statement.

Good job! Now we have an escrow contract which can handle multiple transactions between different parties and arbitrators.
