====================
Arbitrator Interface
====================


.. literalinclude:: ../contracts/IArbitrator.sol
    :language: javascript



Dispute Status
##############

There are three statuses that the function ``disputeStatus`` can return; ``Waiting``, ``Appealable`` and ``Solved``:


* A *dispute* is in ``Waiting`` state when it arises (gets created, by ``createDispute`` function).

* Is in ``Appealable`` state when it got a *ruling* and the ``Arbitrator`` allows to *appeal* it. When the ``Arbitrator`` allows to appeal, it often gives a time period to do so. If a dispute is not appealed within that time, ``disputeStatus`` should return ``Solved``.

* Is in ``Solved`` state when it got a *ruling* and the *ruling* is final. Note that this doesn't imply ``rule`` function on the ``Arbitrable`` has been called to enforce (execute) the *ruling*. It means that the decision on the *dispute* is final and to be executed.


Events
######

There are three events to be emitted:

* ``DisputeCreation`` when a *dispute* gets created by ``createDispute`` function.

* ``AppealPossible`` when appealing a *dispute* becomes possible.

* ``AppealDecision`` when *current ruling* is *appealed*.


Functions
#########

And seven functions:

* ``createDispute`` should create a dispute with given number of possible ``_choices`` for decisions. ``_extraData`` is for passing any extra information for any kind of custom handling.
  While calling ``createDispute``, caller has to pass required *arbitration fee*, otherwise ``createDispute`` should revert. ``createDispute`` should be called by an ``Arbitrable``. Lastly, it should emit ``DisputeCreation`` event.

* ``arbitrationCost`` should return the *arbitration cost* that is required to *create a dispute*, in weis.

* ``appeal`` should appeal a dispute and should require the caller to pass the required *appeal fee*. ``appeal`` should be called by an ``Arbitrable`` and should emit the ``AppealDecision`` event.

* ``appealCost`` should return the *appeal fee* that is required to *appeal*, in weis.

* ``appealPeriod`` should return the time window, in ``(start, end)`` format, for appealing a ruling, if known in advance. If not known or appeal is impossible: should return ``(0, 0)``.

* ``disputeStatus`` should return the status of dispute; ``Waiting``, ``Appealable`` or ``Solved``.

* ``currentRuling`` should return the current ruling of a dispute.
