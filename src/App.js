import React from 'react'
import * as SimpleEscrowWithERC1497 from './simple-escrow-with-erc1497'
import * as Arbitrator from './arbitrator'
import Ipfs from 'ipfs-http-client'
import ipfsPublish from './ipfs-publish'
import web3 from './web3'

import generateMetaevidence from './generate-meta-evidence'
import generateEvidence from './generate-evidence'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Deploy from './deploy.js'
import Interact from './interact.js'

class App extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      activeAddress: '0x0000000000000000000000000000000000000000',
      lastDeployedAddress: '0x0000000000000000000000000000000000000000'
    }
    this.ipfs = new Ipfs({
      host: 'ipfs.kleros.io',
      port: 5001,
      protocol: 'https'
    })
  }

  deploy = async (amount, payee, arbitrator, title, description) => {
    const { activeAddress } = this.state

    let metaevidence = generateMetaevidence(
      web3.utils.toChecksumAddress(activeAddress),
      web3.utils.toChecksumAddress(payee),
      amount,
      title,
      description
    )
    const enc = new TextEncoder()
    const ipfsHashMetaEvidenceObj = await ipfsPublish(
      'metaEvidence.json',
      enc.encode(JSON.stringify(metaevidence))
    )

    let result = await SimpleEscrowWithERC1497.deploy(
      activeAddress,
      payee,
      amount,
      arbitrator,

      '/ipfs/' +
        ipfsHashMetaEvidenceObj[1]['hash'] +
        ipfsHashMetaEvidenceObj[0]['path']
    )

    this.setState({ lastDeployedAddress: result._address })
  }

  load = contractAddress => {
    console.log('app.js')
    console.log(contractAddress)
    return SimpleEscrowWithERC1497.contractInstance(contractAddress)
  }

  reclaimFunds = async (contractAddress, value) => {
    const { activeAddress } = this.state
    console.log(activeAddress)
    await SimpleEscrowWithERC1497.reclaimFunds(
      activeAddress,
      contractAddress,
      value
    )
  }

  releaseFunds = async contractAddress => {
    const { activeAddress } = this.state
    console.log(activeAddress)

    await SimpleEscrowWithERC1497.releaseFunds(activeAddress, contractAddress)
  }

  depositArbitrationFeeForPayee = (contractAddress, value) => {
    const { activeAddress } = this.state

    SimpleEscrowWithERC1497.depositArbitrationFeeForPayee(
      activeAddress,
      contractAddress,
      value
    )
  }

  reclamationPeriod = contractAddress =>
    SimpleEscrowWithERC1497.reclamationPeriod(contractAddress)

  arbitrationFeeDepositPeriod = contractAddress =>
    SimpleEscrowWithERC1497.arbitrationFeeDepositPeriod(contractAddress)

  remainingTimeToReclaim = contractAddress => {
    return SimpleEscrowWithERC1497.remainingTimeToReclaim(contractAddress)
  }

  remainingTimeToDepositArbitrationFee = contractAddress => {
    return SimpleEscrowWithERC1497.remainingTimeToDepositArbitrationFee(
      contractAddress
    )
  }

  arbitrationCost = (arbitratorAddress, extraData) => {
    return Arbitrator.arbitrationCost(arbitratorAddress, extraData)
  }

  arbitrator = contractAddress => {
    return SimpleEscrowWithERC1497.arbitrator(contractAddress)
  }

  status = contractAddress => {
    return SimpleEscrowWithERC1497.status(contractAddress)
  }

  value = contractAddress => {
    return SimpleEscrowWithERC1497.value(contractAddress)
  }

  submitEvidence = async (contractAddress, evidenceBuffer) => {
    const { activeAddress } = this.state

    const result = await ipfsPublish('name', evidenceBuffer)
    console.log(result)

    let evidence = generateEvidence(
      '/ipfs/' + result[0]['hash'],
      'name',
      'description'
    )
    const enc = new TextEncoder()
    const ipfsHashEvidenceObj = await ipfsPublish(
      'evidence.json',
      enc.encode(JSON.stringify(evidence))
    )

    console.log(ipfsHashEvidenceObj)

    SimpleEscrowWithERC1497.submitEvidence(
      contractAddress,
      activeAddress,
      '/ipfs/' + ipfsHashEvidenceObj[0]['hash']
    )
  }

  async componentDidMount() {
    if (window.web3 && window.web3.currentProvider.isMetaMask)
      window.web3.eth.getAccounts((_, accounts) => {
        this.setState({ activeAddress: accounts[0] })
      })
    else console.log('MetaMask account not detected :(')

    window.ethereum.on('accountsChanged', accounts => {
      this.setState({ activeAddress: accounts[0] })
    })
  }

  render() {
    const { lastDeployedAddress } = this.state
    return (
      <Container>
        <Row>
          <Col>
            <h1 className="text-center my-5">
              A Simple DAPP Using SimpleEscrowWithERC1497
            </h1>
          </Col>
        </Row>

        <Row>
          <Col>
            <Deploy deployCallback={this.deploy} />
          </Col>
          <Col>
            <Interact
              arbitratorCallback={this.arbitrator}
              arbitrationCostCallback={this.arbitrationCost}
              escrowAddress={lastDeployedAddress}
              loadCallback={this.load}
              reclaimFundsCallback={this.reclaimFunds}
              releaseFundsCallback={this.releaseFunds}
              depositArbitrationFeeForPayeeCallback={
                this.depositArbitrationFeeForPayee
              }
              remainingTimeToReclaimCallback={this.remainingTimeToReclaim}
              remainingTimeToDepositArbitrationFeeCallback={
                this.remainingTimeToDepositArbitrationFee
              }
              statusCallback={this.status}
              valueCallback={this.value}
              submitEvidenceCallback={this.submitEvidence}
            />
          </Col>
        </Row>
      </Container>
    )
  }
}

export default App
