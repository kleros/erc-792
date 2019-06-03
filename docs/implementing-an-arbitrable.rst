==========================
Implementing an Arbitrable
==========================

.. warning::
  Smart contracts in this tutorial are not intended for production but educational purposes. Beware of using them on main network.


When developing arbitrable contracts, we need to:

* Implement ``rule`` function to define an action to be taken when a ruling is received by the contract.
* Develop a logic to create disputes (via calling ``createDispute`` on Arbitrable)

Consider a case where two parties trade ether for goods. Payer wants to pay only if payee provides promised goods. So payer deposits payment amount into an escrow and if a dispute arises an arbitrator will resolve it.

There will be two scenarios:
 1. No dispute arises, ``payee`` withdraws the funds.
 2. ``payer`` reclaims funds by depositing arbitration fee...
      a. ``payee`` fails to deposit arbitration fee in ``arbitrationFeeDepositPeriod`` and ``payer`` wins by default. The arbitration fee deposit paid by ``payer`` refunded.
      b. ``payee`` deposits arbitration fee in time. Dispute gets created. ``arbitrator`` rules. Winner gets the arbitration fee refunded.

Notice that only in scenario 2b ``arbitrator`` intervenes. In other scenarios we don't create a dispute thus don't await for a ruling.
Also, notice that in case of a dispute, the winning side gets reimbursed for the arbitration fee deposit. So in effect, the loser will be paying for the arbitration.






Let's start:


.. literalinclude:: ../contracts/examples/SimpleEscrow.sol
    :language: javascript
    :lines: 1-14,24-30


``payer`` deploys the contract depositing the payment amount and specifying ``payee`` address, ``arbitrator`` that is authorized to rule and ``agreement`` string. Notice that ``payer = msg.sender``.

We made ``reclamationPeriod`` and ``arbitrationFeeDepositPeriod`` constant for sake of simplicity, they could be set by ``payer`` in the constructor too.

Let's implement the first scenario:


.. literalinclude:: ../contracts/examples/SimpleEscrow.sol
    :language: javascript
    :lines: 1-19,24-41
    :emphasize-lines: 17,18,29-37


In ``releaseFunds`` function, first we do state checks: transaction should be in ``Status.Initial`` and ``reclamationPeriod`` should be passed unless the caller is ``payer``.
If so, we update ``status`` to ``Status.Resolved`` and send the funds to ``payee``.

Moving forward to second scenario:

.. literalinclude:: ../contracts/examples/SimpleEscrow.sol
    :language: javascript
    :emphasize-lines: 20,22,23,42-


``reclaimFunds`` function lets ``payer`` to reclaim their funds. After ``payer`` calls this function for the first time the window (``arbitrationFeeDepositPeriod``) for ``payee`` to deposit arbitration fee starts.
If they fail to deposit in time, ``payer`` can call the function for the second time and get the funds back.
In case if ``payee`` deposits the arbitration fee in time a *dispute* gets created and the contract awaits arbitrator's decision.

We define enforcement of rulings in ``rule`` function. Whoever wins the dispute should get the funds and should get reimbursed for the arbitration fee.
Recall that we took the arbitration fee deposit from both sides and used one of them to pay for the arbitrator. Thus the balance of the contract is at least funds plus arbitration fee. Therefore we send ``address(this).balance`` to the winner. Lastly, we emit ``Ruling`` as required in the standard.

And also we have two view functions to get remaining times, which will be useful for front-end development.

That's it! We implemented a very simple escrow using ERC-792.
