=================================
Implementing a Complex Arbitrable
=================================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

Let's implement a full-fledged escrow this time, extending ``SimpleEscrowWithERC1497`` contract we implemented earlier. We will call it just ``Escrow`` this time.

Recall ``SimpleEscrowWithERC1497``:

.. literalinclude:: ../contracts/examples/SimpleEscrowWithERC1497.sol
    :language: javascript


Payer needs to deploy a contract for each transaction, but contract deployment is expensive.
Instead we could use the same contract for multiple transactions between arbitrary parties with arbitrary arbitrators.

Let's separate contract deployment and transaction creation:

.. literalinclude:: ../contracts/examples/Escrow.sol
    :language: javascript
    :emphasize-lines: 9-116


We first start by removing global state variables and defining ``TX`` struct. Each instance of this struct will represent a transaction thus will have transaction specific variables instead of globals.
We will store transactions inside ``txs`` array. And will create new transactions via ``newTransaction`` function.

``newTransaction`` function simply takes transaction specific information and push a ``TX`` into ``txs``. This ``txs`` array is append-only, we will never remove any item.
Having this, we will uniquely identify each transaction by their index in the array.

Next, we update all the functions with transaction specific variables instead of globals. Changes are merely adding ``tx.`` prefixes in front of expressions.

We don't ``send(address(this).balance)`` now as the contract balance includes funds from all transactions. Instead we store deposited fee amounts and use following expression: ``tx.payer.send(tx.value + tx.payerFeeDeposit);``.

Good job, now we have an escrow contract which can handle multiple transactions between different parties and arbitrators.
