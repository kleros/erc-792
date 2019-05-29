import SimpleEscrowWithERC1497 from './simple-escrow-with-erc1497.json'
import web3 from './web3'

export const contractInstance = address =>
  new web3.eth.Contract(SimpleEscrowWithERC1497.abi, address)

export const deploy = (payer, payee, amount, arbitrator, metaevidence) =>
  new web3.eth.Contract(SimpleEscrowWithERC1497.abi)
    .deploy({
      arguments: [payee, arbitrator, metaevidence],
      data: SimpleEscrowWithERC1497.bytecode
    })
    .send({ from: payer, value: amount })

export const reclaimFunds = (senderAddress, instanceAddress, value) =>
  contractInstance(instanceAddress)
    .methods.reclaimFunds()
    .send({ from: senderAddress, value })

export const releaseFunds = (senderAddress, instanceAddress) =>
  contractInstance(instanceAddress)
    .methods.releaseFunds()
    .send({ from: senderAddress })

export const depositArbitrationFeeForPayee = (
  senderAddress,
  instanceAddress,
  value
) =>
  contractInstance(instanceAddress)
    .methods.depositArbitrationFeeForPayee()
    .send({ from: senderAddress, value })

export const reclamationPeriod = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.reclamationPeriod()
    .call()

export const arbitrationFeeDepositPeriod = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.arbitrationFeeDepositPeriod()
    .call()

export const createdAt = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.createdAt()
    .call()

export const remainingTimeToReclaim = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.remainingTimeToReclaim()
    .call()

export const remainingTimeToDepositArbitrationFee = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.remainingTimeToDepositArbitrationFee()
    .call()

export const arbitrator = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.arbitrator()
    .call()

export const status = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.status()
    .call()

export const value = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.value()
    .call()

export const submitEvidence = (instanceAddress, senderAddress, evidence) =>
  contractInstance(instanceAddress)
    .methods.submitEvidence(evidence)
    .send({ from: senderAddress })
