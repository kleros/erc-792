import SimpleEscrowWithERC1497 from './SimpleEscrowWithERC1497.json'
import web3 from './web3'

export const deploy = (payer, payee, amount, arbitrator, metaevidence) =>
  new web3.eth.Contract(SimpleEscrowWithERC1497.abi)
    .deploy({
      arguments: [payee, arbitrator, metaevidence],
      data: SimpleEscrowWithERC1497.bytecode
    })
    .send({ from: payer, value: amount })

export const contractInstance = address => {
  let instance = new web3.eth.Contract(SimpleEscrowWithERC1497.abi, address)
  instance.options.address = '0x575Cf3cf95F063b678580D5338829194C55Df6F0'

  return instance
}

export const reclaimFunds = async (senderAddress, instanceAddress) =>
  contractInstance(instanceAddress)
    .methods.reclaimFunds()
    .send({ from: senderAddress })

export const releaseFunds = async (senderAddress, instanceAddress) =>
  contractInstance(instanceAddress)
    .methods.releaseFunds()
    .send({ from: senderAddress })

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
