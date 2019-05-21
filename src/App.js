import React from 'react'
import * as SimpleEscrowWithERC1497 from './simple-escrow-with-erc1497'
import generateMetaevidence from './generate-meta-evidence'
import web3 from './web3'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Deploy from './deploy.js'
import Interact from './interact.js'

class App extends React.Component {
  constructor(props) {
    super(props)
    this.state = { activeAddress: '0x0000000000000000000000000000000000000000' }
  }

  deploy = async (amount, payee, arbitrator, title, description) => {
    console.log('deploy called')
    const { activeAddress } = this.state

    await SimpleEscrowWithERC1497.deploy(
      activeAddress,
      payee,
      amount,
      arbitrator,
      ''
    )
  }

  load = contractAddress =>
    SimpleEscrowWithERC1497.contractInstance(contractAddress)

  reclaimFunds = async contractAddress => {
    const { activeAddress } = this.state
    console.log(activeAddress)
    await SimpleEscrowWithERC1497.reclaimFunds(activeAddress, contractAddress)
  }

  releaseFunds = async contractAddress => {
    const { activeAddress } = this.state
    console.log(activeAddress)

    await SimpleEscrowWithERC1497.releaseFunds(activeAddress, contractAddress)
  }

  depositArbitrationFeeFromPayee = async () => {}

  reclamationPeriod = contractAddress =>
    SimpleEscrowWithERC1497.reclamationPeriod(contractAddress)

  arbitrationFeeDepositPeriod = contractAddress =>
    SimpleEscrowWithERC1497.arbitrationFeeDepositPeriod(contractAddress)

  remainingTimeToReclaim = contractAddress => {
    SimpleEscrowWithERC1497.remainingTimeToReclaim(contractAddress)
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
    return (
      <Container>
        <Row>
          <Col>
            <header>Simple Escrow</header>
          </Col>
        </Row>

        <Row>
          <Col>
            <Deploy deployCallback={this.deploy} />
          </Col>
          <Col>
            <Interact
              loadCallback={this.load}
              reclaimFundsCallback={this.reclaimFunds}
              releaseFundsCallback={this.releaseFunds}
              depositArbitrationFeeFromPayeeCallback={
                this.depositArbitrationFeeFromPayee
              }
              remainingTimeToReclaimCallback={this.remainingTimeToReclaim}
            />
          </Col>
        </Row>
      </Container>
    )
  }
}

export default App
