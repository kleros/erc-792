================
A Simple DApp
================

Let's implement a simple decentralized application using ``SimpleEscrowWithERC1497`` and ``SimpleCentralizedArbitrator`` contracts. As we have the contract ready already

We will create a simplest possible UI as front-end development is out of the scope of this tutorial.

Tools used in this tutorial:

* Yarn
* React
* Create React App
* Bootstrap
* IPFS
* Infura
* MetaMask


Scaffolding The Project And Installing Dependencies
###################################################

1. Run ``yarn create react-app a-simple-dapp`` to create a directory "a-simple-dapp" under your working directory and scaffold your application.

2. Use ``yarn add <package-name-here>`` to install following dependencies. Using exact versions is recommended.

.. literalinclude:: ../package.json
    :language: javascript
    :start-after: dependencies
    :end-before: }

3. Inside the application directory, running ``yarn start`` should run your application now. By default it runs on `port 3000 <http://localhost:3000>`_.


Ethereum Interface
##################

Setting Up Web3
***************

.. literalinclude:: ../src/ethereum/web3.js
  :language: javascript

Preparing Helper Functions For Arbitrator
*****************************************

.. literalinclude:: ../src/ethereum/arbitrator.js
    :language: javascript


Preparing Helper Functions For Arbitrable
*****************************************

.. literalinclude:: ../src/ethereum/simple-escrow-with-erc1497.js
  :language: javascript

Evidence and Meta-Evidence Helpers
**********************************

.. literalinclude:: ../src/ethereum/generate-evidence.js
  :language: javascript

.. literalinclude:: ../src/ethereum/generate-meta-evidence.js
  :language: javascript

Evidence Storage
################

.. literalinclude:: ../src/ipfs-publish.js
  :language: javascript


React Components
################


App
***
.. literalinclude:: ../src/app.js
  :language: jsx

Deploy
******

.. literalinclude:: ../src/deploy.js
  :language: jsx

Interact
********
.. literalinclude:: ../src/interact.js
  :language: jsx
