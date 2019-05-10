==========
Arbitrable
==========

.. code-block::none
  :linenothreshold: 10

interface IArbitrable {

    function rule(uint _disputeID, uint _ruling) external;

    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

}


``rule`` is the function to be called by ``Arbitrator`` to give a *ruling* to a *dispute*.

``Ruling`` is the event which has to be emitted whenever a *final ruling* is given.  For example, inside ``rule`` function, where the ruling is final and gets enforced.
