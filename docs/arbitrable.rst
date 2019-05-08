==========
Arbitrable
==========

.. code-block::javascript

interface IArbitrable {

    function rule(uint _disputeID, uint _ruling) external;

    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

}


``rule`` is the function to be called by the ``Arbitrator`` to give a *ruling* to a *dispute*.

``Ruling`` is the event which has to be emitted whenever a *ruling* is given thus inside the ``rule`` function.
