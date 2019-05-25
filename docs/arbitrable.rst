====================
Arbitrable Interface
====================

.. literalinclude:: ../contracts/IArbitrable.sol
    :language: javascript


``rule`` is the function to be called by ``Arbitrator`` to enforce a *ruling* to a *dispute*.

``Ruling`` is the event which has to be emitted whenever a *final ruling* is given.  For example, inside ``rule`` function, where the ruling is final and gets enforced.
