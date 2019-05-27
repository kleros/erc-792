*************
A Simple DApp
*************

.. note::
  You can find the finished React project source code `here <https://github.com/kleros/erc-792/tree/master/src>`_. You can test it live `here <https://simple-escrow.netlify.com/>`_.


Let's implement a simple decentralized application using ``SimpleEscrowWithERC1497`` contract.

We will create a simplest possible UI as front-end development is out of the scope of this tutorial.

Tools used in this tutorial:

* Yarn
* React
* Create React App
* Bootstrap
* IPFS
* MetaMask


Arbitrable Side
###############

Scaffolding The Project And Installing Dependencies
***************************************************

1. Run ``yarn create react-app a-simple-dapp`` to create a directory "a-simple-dapp" under your working directory and scaffold your application.

2. Run ``yarn add ipfs-http-client@32.0.1 web3@1.0.0-beta.37 react-bootstrap`` to install required dependencies. Using exact versions for web3 and ipfs-http-client is recommended.


3. Inside the application directory, running ``yarn start`` should run your application now. By default it runs on `port 3000 <http://localhost:3000>`_.


Ethereum Interface
******************

Under the ``src`` directory, let's create a directory called ``ethereum`` for ethereum related files.

Setting Up Web3
===============


Let's create a new file called ``web3.js`` under ``ethereum`` directory. We will put a helper inside it which will let us access MetaMask for sending transactions and querying the blockchain. For more detail please see `MetaMask documentation <https://metamask.github.io/metamask-docs/API_Reference/Ethereum_Provider>`_ .


.. literalinclude:: ../src/ethereum/web3.js
  :language: javascript
  :caption: web3.js
  :name: web3

Preparing Helper Functions For SimpleEscrowWithERC1497 And Arbitrator Contracts
===============================================================================

We need to call functions of ``SimpleEscrowWithERC1497`` and the arbitrator (for ``arbitrationCost``, to be able to send correct amount when creating a dispute), so we need helpers for them.

We will import build artifacts of ``SimpleEscrowWithERC1497`` and ``Arbitrator`` contracts to use their abis (`application binary interface <https://ethereum.stackexchange.com/questions/234/what-is-an-abi-and-why-is-it-needed-to-interact-with-contracts>`_).
So we copy those under ``ethereum`` directory and create two helper files (``arbitrator.js`` and ``simple-escrow-with-erc1497.js``) using each of them.



.. literalinclude:: ../src/ethereum/simple-escrow-with-erc1497.js
  :language: javascript
  :caption: simple-escrow-with-erc1497.js
  :name: simple-escrow-with-erc1497

.. literalinclude:: ../src/ethereum/arbitrator.js
    :language: javascript
    :caption: arbitrator.js
    :name: arbitrator

Evidence and Meta-Evidence Helpers
==================================

Recall `Evidence Standard <https://github.com/ethereum/EIPs/issues/1497>`_ JSON format. These two javascript object factories will be used to create JSON objects according to the standard.

.. literalinclude:: ../src/ethereum/generate-evidence.js
  :language: javascript
  :caption: generate-evidence.js
  :name: generate-evidence

.. literalinclude:: ../src/ethereum/generate-meta-evidence.js
  :language: javascript
  :caption: generate-meta-evidence.js
  :name: generate-meta-evidence

Evidence Storage
****************

We want to make sure evidence files are tamper-proof. So we need an immutable file storage. `IPFS <https://ipfs.io/#why>`_ is perfect fit for this use-case.
The following helper will let us publish evidence on IPFS, through the IPFS node at https://ipfs.kleros.io .

.. literalinclude:: ../src/ipfs-publish.js
  :language: javascript
  :caption: ipfs-publish.js
  :name: ipfs-publish


React Components
****************

We will create a single-page react application to keep it simple. The main component, ``App`` will contain two sub-components:

* ``Deploy``
* ``Interact``

``Deploy`` component will contain a form for arguments of ``SimpleEscrowWithERC1497`` deployment and a deploy button.

``Interact`` component will have an input field for entering a contract address that is deployed already, to interact with. It will also have badges to show some state variable values of the contract.
In addition, it will have three buttons for three main functions: ``releaseFunds``, ``reclaimFunds`` and ``depositArbitrationFeeForPayee``.
Lastly, it will have a file picker and submit button for submitting evidence.

``App`` will be responsible for accessing Ethereum. So it will give callbacks to ``Deploy`` and ``Interact`` to let them access Ethereum through ``App``.

App
===
.. literalinclude:: ../src/app.js
  :language: jsx
  :caption: app.js
  :name: app

Deploy
======

.. literalinclude:: ../src/deploy.js
  :language: jsx
  :caption: deploy.js
  :name: deploy

Interact
========
.. literalinclude:: ../src/interact.js
  :language: jsx
  :caption: interact.js
  :name: interact


Arbitrator Side
###############

We can deploy a ``SimpleCentralizedArbitrator`` to use as the arbitrator on the DApp we developed. For deployment, using `Remix <https://remix.ethereum.org/>`_ is recommended.
To interact with the arbitrator, we can use `Centralized Arbitrator Dashboard <https://centralizedarbitrator.fyi>`_ by simply inputting contract address.
