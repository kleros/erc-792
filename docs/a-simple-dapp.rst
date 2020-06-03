*************
A Simple DApp
*************

.. note::
  This tutorial requires basic Javascript programming skills and basic understanding of React Framework.

.. note::
  You can find the finished React project `source code here <https://github.com/kleros/erc-792/tree/master/src>`_. You can test it `live here <https://simple-escrow.netlify.com/>`_.


Let's implement a simple decentralized application using ``SimpleEscrowWithERC1497`` contract.

We will create the simplest possible UI, as front-end development is out of the scope of this tutorial.

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

2. Run ``yarn add web3@1.0.0-beta.37 react-bootstrap`` to install required dependencies. Using exact versions for web3 and ipfs-http-client is recommended.

3. Add the following Bootstrap styleshet in ``index.html``

.. code-block:: javascript

  <link
  rel="stylesheet"
  href="https://maxcdn.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
  integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T"
  crossorigin="anonymous"
  />

4. Inside the application directory, running ``yarn start`` should run your application now. By default it runs on `port 3000 <http://localhost:3000>`_.



Ethereum Interface
******************

Under the ``src`` directory, let's create a directory called ``ethereum`` for Ethereum-related files.

Setting Up Web3
===============


Let's create a new file called ``web3.js`` under ``ethereum`` directory. We will put a helper inside it which will let us access MetaMask for sending transactions and querying the blockchain. For more details please see `the MetaMask documentation <https://metamask.github.io/metamask-docs/API_Reference/Ethereum_Provider>`_ .


.. literalinclude:: ../src/ethereum/web3.js
  :language: javascript
  :caption: web3.js
  :name: web3

Preparing Helper Functions For SimpleEscrowWithERC1497 And Arbitrator Contracts
===============================================================================

We need to call functions of ``SimpleEscrowWithERC1497`` and the arbitrator (for ``arbitrationCost``, to be able to send the correct amount when creating a dispute), so we need helpers for them.

We will import build artifacts of ``SimpleEscrowWithERC1497`` and ``Arbitrator`` contracts to use their ABIs (`application binary interface <https://ethereum.stackexchange.com/questions/234/what-is-an-abi-and-why-is-it-needed-to-interact-with-contracts>`_).
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

To interact with an arbitrator, we can use `Centralized Arbitrator Dashboard <https://centralizedarbitrator.netlify.com>`_. It let's setting up an arbitrator easily and provides UI to interact with, very useful for debugging and testing arbitrable implementations. As arbitrator, it deploys `AutoAppealableArbitrator <https://github.com/kleros/kleros-interaction/blob/master/contracts/standard/arbitration/AutoAppealableArbitrator.sol>`_ which is very similar to the one we developed in the tutorials.

To Use Centralized Arbitrator Dashboard (CAD):

1. Deploy a new arbitrator by specifying arbitration fee, choose a tiny amount for convenience, like `0.001` Ether.
2. Copy the arbitrator address and use this address as the arbitrator, in your arbitrable contract.
3. Create a dispute on your arbitrable contract.
4. Go back to CAD, select the arbitrator you created in the first step, by entering the contract address.
5. Now you should be able to see the dispute you created. You can give rulings to it using CAD.

Alternatively, you can use `Kleros Arbitrator on Kovan network <https://kovan.etherscan.io/address/0x60b2abfdfad9c0873242f59f2a8c32a3cc682f80>`_ for testing. In that case, use this arbitrator address in your arbitrable contract, then simply go to https://court.kleros.io and switch your web3 provider to Kovan network. To be able to stake in a court, you will need Kovan PNK token, which you can buy from https://court.kleros.io/tokens.

Finally, when your arbitrable contract is ready, use `Kleros Arbitrator on main network <https://etherscan.io/address/0x988b3a538b618c7a603e1c11ab82cd16dbe28069#code>`_ to integrate with Kleros.
