===============
Introduction
===============

.. warning::
  This documentation is work-in-progress.

.. note::
  This tutorial requires basic Solidity programming skills.

ERC-792: Arbitration Standard proposes a standard for arbitration on Ethereum. The standard has two types of smart contracts: ``Arbitrable`` and ``Arbitrator``.

``Arbitrable`` contracts are the contracts on which *rulings* of the authorized ``Arbitrator`` are enforceable.

``Arbitrator`` contracts are the contracts which give *rulings* in case of *disputes*.

In other words, ``Arbitrator`` gives rulings, and ``Arbitrable`` enforces them.
