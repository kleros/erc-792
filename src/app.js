import React from 'react'
import web3 from './ethereum/web3'
import generateEvidence from './ethereum/generate-evidence'
import generateMetaevidence from './ethereum/generate-meta-evidence'
import * as SimpleEscrowWithERC1497 from './ethereum/simple-escrow-with-erc1497'
import * as Arbitrator from './ethereum/arbitrator'
import Ipfs from 'ipfs-http-client'
import ipfsPublish from './ipfs-publish'

import Container from 'react-bootstrap/Container'
import Jumbotron from 'react-bootstrap/Jumbotron'
import Button from 'react-bootstrap/Button'
import Form from 'react-bootstrap/Form'
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

  load = contractAddress =>
    SimpleEscrowWithERC1497.contractInstance(contractAddress)

  reclaimFunds = async (contractAddress, value) => {
    const { activeAddress } = this.state
    await SimpleEscrowWithERC1497.reclaimFunds(
      activeAddress,
      contractAddress,
      value
    )
  }

  releaseFunds = async contractAddress => {
    const { activeAddress } = this.state

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

  remainingTimeToReclaim = contractAddress =>
    SimpleEscrowWithERC1497.remainingTimeToReclaim(contractAddress)

  remainingTimeToDepositArbitrationFee = contractAddress =>
    SimpleEscrowWithERC1497.remainingTimeToDepositArbitrationFee(
      contractAddress
    )

  arbitrationCost = (arbitratorAddress, extraData) =>
    Arbitrator.arbitrationCost(arbitratorAddress, extraData)

  arbitrator = contractAddress =>
    SimpleEscrowWithERC1497.arbitrator(contractAddress)

  status = contractAddress => SimpleEscrowWithERC1497.status(contractAddress)

  value = contractAddress => SimpleEscrowWithERC1497.value(contractAddress)

  submitEvidence = async (contractAddress, evidenceBuffer) => {
    const { activeAddress } = this.state

    const result = await ipfsPublish('name', evidenceBuffer)

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
    else console.error('MetaMask account not detected :(')

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
        <Row>
          <Col>
            <Form action="https://centralizedarbitrator.netlify.com">
              <Jumbotron className="m-5 text-center">
                <h1>Need to interact with your arbitrator contract?</h1>
                <p>
                  We have a general purpose user interface for centralized
                  arbitrators (like we have developed in the tutorial) already.
                </p>
                <p>
                  <Button type="submit" variant="primary">
                    Visit Centralized Arbitrator Dashboard
                  </Button>
                </p>
              </Jumbotron>
            </Form>
          </Col>
        </Row>
      </Container>
    )
  }
}

export default App
