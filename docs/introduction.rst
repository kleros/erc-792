===============
Introduction
===============

.. warning::
  This tutorial is work-in-progress.

.. note::
  This tutorial requires basic Solidity programming skills.

.. note:: For complete specification of the standard you can read the original proposal `here <https://github.com/ethereum/EIPs/issues/792>`_.

ERC-792: Arbitration Standard proposes a standard for arbitration on Ethereum. The standard has two types of smart contracts: ``Arbitrable`` and ``Arbitrator``.

``Arbitrable`` contracts are the contracts on which *rulings* of the authorized ``Arbitrator`` are enforceable.

``Arbitrator`` contracts are the contracts which give *rulings* on disputes.

In other words, ``Arbitrator`` gives rulings, and ``Arbitrable`` enforces them.



In the following topics, you will be guided through the usage of the standard. You can find the contracts used in this tutorial `here <https://github.com/kleros/erc-792/tree/master/contracts>`_.
