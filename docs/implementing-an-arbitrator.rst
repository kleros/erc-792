==========================
Implementing an Arbitrator
==========================

CentralizedArbitrator
#####################

First we will implement a very simple arbitrator where single wallet gives rulings and there won't be any appeals.

Let's start by implementing cost functions:

.. code-block:: javascript

  pragma solidity ^0.5.8;

  import "../Arbitrator.sol";

  contract CentralizedArbitrator is Arbitrator {

  }
