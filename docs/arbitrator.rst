==========
Arbitrator
==========


.. code-block:: javascript

  contract Arbitrator {

      enum DisputeStatus {Waiting, Appealable, Solved}

      modifier requireArbitrationFee(bytes memory _extraData) {
          require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
          _;

      }

      modifier requireAppealFee(uint _disputeID, bytes memory _extraData) {
          require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
          _;

      }

      event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

      event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

      event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

      function createDispute(uint _choices, bytes memory _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

      function arbitrationCost(bytes memory _extraData) public view returns(uint fee);

      function appeal(uint _disputeID, bytes memory _extraData) public requireAppealFee(_disputeID,_extraData) payable {
          emit AppealDecision(_disputeID, Arbitrable(msg.sender));

      }

      function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee);

      function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

      function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

      function currentRuling(uint _disputeID) public view returns(uint ruling);

  }


Dispute Status
##############

*Disputes* has three statuses: ``Waiting`` , ``Appealable`` and ``Solved`` :

* A *dispute* is in ``Waiting`` state when it arises (get's created, by ``createDispute`` function).

* Is in ``Appealable`` state when it got a *ruling* and if the ``Arbitrator`` lets to appeal a *ruling*. When the ``Arbitrator`` lets to appeal, often it gives a time period to do so, after that the dispute will no longer be ``Appealable`` but ``Solved``.

* Is in ``Solved`` state when it got a *ruling* and the *ruling* is final. Note that this doesn't imply ``rule`` function on the ``Arbitrable`` has been called to execute the *ruling*. It means the decision on the *dispute* is final and to be executed.


Events
######

There are three events to be emitted:

* ``DisputeCreation`` when a *dispute* gets created by ``createDispute`` function.

* ``AppealPossible`` when appealing a *dispute* becomes possible.

* ``AppealDecision`` when *current ruling* is *appealed*.


Functions
#########

And seven functions:

* ``createDispute`` should create a dispute with given number of possible ``_choices`` for decisions. ``_extraData`` is for passing any extra information for any kind of custom handling. While calling ``createDispute``, caller has to pass required *arbitration fee*, otherwise ``createDispute`` should revert. ``createDispute`` should be called by the ``Arbitrable``.

* ``arbitrationCost`` should return the *arbitration fee* that is required to *create a dispute*, in weis.

* ``appeal`` should appeal a dispute and should require caller to pass required *appeal fee*. ``appeal`` should be called by ``Arbitrable`` and should emit ``AppealDecision`` event.

* ``appealCost`` should return the *appeal fee* that is required to *appeal*, in weis.

* ``appealPeriod`` should return the time window, in ``(start, end)`` format, for appealing a ruling, if known in advance. If not known or appeal is impossible: should return ``(0, 0)``.

* ``disputeStatus`` should return the status of dispute; ``Waiting``, ``Appealable`` or ``Solved``.

* ``currentRuling`` should return the ruling which will be given if there is no appeal or which has been given.
