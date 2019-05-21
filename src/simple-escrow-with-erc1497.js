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
    .methods.createdAt()
    .call()

export const remainingTimeToDepositArbitrationFee = instanceAddress =>
  contractInstance(instanceAddress)
    .methods.remainingTimeToDepositArbitrationFee()
    .call()

// export const getArbitrationCost = async (arbitratorInstance, extraData) =>
//   arbitratorInstance.methods
//     .arbitrationCost(web3.utils.utf8ToHex(extraData))
//     .call()
//
// export const setArbitrationPrice = async (
//   account,
//   arbitratorInstance,
//   arbitrationPrice
// ) =>
//   arbitratorInstance.methods
//     .setArbitrationPrice(arbitrationPrice)
//     .send({ from: account })
//
// export const getDispute = async (arbitratorInstance, index) =>
//   arbitratorInstance.methods.disputes(index).call()
//
// export const getDisputeStatus = async (arbitratorInstance, index) =>
//   arbitratorInstance.methods.disputeStatus(index).call()
//
// export const giveRuling = async (
//   account,
//   arbitratorInstance,
//   disputeID,
//   ruling
// ) =>
//   arbitratorInstance.methods
//     .giveRuling(disputeID, ruling)
//     .send({ from: account })
//
// export const giveAppealableRuling = async (
//   account,
//   arbitratorInstance,
//   disputeID,
//   ruling,
//   appealCost,
//   timeToAppeal
// ) =>
//   arbitratorInstance.methods
//     .giveAppelableRuling(disputeID, ruling, appealCost, timeToAppeal)
//     .send({ from: account })
