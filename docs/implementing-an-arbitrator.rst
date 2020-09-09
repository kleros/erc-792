==========================
Implementing an Arbitrator
==========================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.

When developing arbitrator contracts we need to:

* Implement the functions ``createDispute`` and ``appeal``. Don't forget to store the arbitrated contract and the disputeID (which should be unique).
* Implement the functions for cost display (``arbitrationCost`` and ``appealCost``).
* Allow enforcing rulings. For this a function must execute ``arbitrable.rule(disputeID, ruling)``.


To demonstrate how to use the standard, we will implement a very simple arbitrator where a single address gives rulings and there aren't any appeals.

Let's start by implementing cost functions:

.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-5,17-25


We set the arbitration fee to ``0.1 ether`` and the appeal fee to an astronomical amount which can't be afforded.
So in practice, we disabled appeal, for simplicity. We made costs constant, again, for the sake of simplicity of this tutorial.

Next, we need a data structure to keep track of disputes:


.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-5,8-25
    :emphasize-lines: 7-14



Each dispute belongs to an ``Arbitrable`` contract, so we have ``arbitrated`` field for it.
Each dispute will have a ruling stored in ``ruling`` field: For example, Party A wins (represented by ``ruling = 1``) and Party B wins (represented by ``ruling = 2``), recall that ``ruling = 0`` is reserved for "refused to arbitrate".
We also store number of ruling options in ``choices`` to be able to avoid undefined rulings in the proxy function which executes ``arbitrable.rule(disputeID, ruling)``.
Finally, each dispute will have a status, and we store it inside ``status`` field.

Next, we can implement the function for creating disputes:


.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-5,8-37
    :emphasize-lines: 24-35

Note that ``createDispute`` function should be called by an *arbitrable*.

We require the caller to pay at least ``arbitrationCost(_extraData)``. We could send back the excess payment, but we omitted it for the sake of simplicity.

Then, we create the dispute by pushing a new element to the array: ``disputes.push( ... )``.
The ``push`` function returns the resulting size of the array, thus we can use the return value of ``disputes.push( ... ) -1`` as ``disputeID`` starting from zero.
Finally, we emit ``DisputeCreation`` as required in the standard.

We also need to implement getters for ``status`` and ``ruling``:



.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-5,8-50
    :emphasize-lines: 36-48



Finally, we need a proxy function to call ``rule`` function of the ``Arbitrable`` contract. In this simple ``Arbitrator`` we will let one address, the creator of the contract, to give rulings. So let's start by storing contract creator's address:

.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-45
    :emphasize-lines: 7


Then the proxy function:

.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :lines: 1-60
    :emphasize-lines: 46-


First we check the caller address, we should only let the ``owner`` execute this. Then we do sanity checks: the ruling given by the arbitrator should be chosen among the ``choices`` and it should not be possible to ``rule`` on an already solved dispute.
Afterwards, we update ``ruling`` and ``status`` values of the dispute. Then we pay arbitration fee to the arbitrator (``owner``). Finally, we call ``rule`` function of the ``arbitrated`` to enforce the ruling.


Lastly, appeal functions:


.. literalinclude:: ../contracts/examples/SimpleCentralizedArbitrator.sol
    :language: javascript
    :emphasize-lines: 61-

Just a dummy implementation to conform the interface, as we don't actually implement appeal functionality.

That's it, we have a working, very simple centralized arbitrator!
