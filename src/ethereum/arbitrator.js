import Arbitrator from './arbitrator.json'
import web3 from './web3'

export const contractInstance = address =>
  new web3.eth.Contract(Arbitrator.abi, address)

export const arbitrationCost = (instanceAddress, extraData) =>
  contractInstance(instanceAddress)
    .methods.arbitrationCost(web3.utils.utf8ToHex(extraData))
    .call()
