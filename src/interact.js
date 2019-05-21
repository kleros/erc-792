import React from 'react'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Badge from 'react-bootstrap/Badge'

class Interact extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      escrowAddress: '0x575Cf3cf95F063b678580D5338829194C55Df6F0',
      remainingTimeToReclaim: 0
    }
  }

  onEscrowAddressChange = e => {
    this.setState({ escrowAddress: e.target.value })
  }

  onLoadButtonClick = e => {
    e.preventDefault()
    const { escrowAddress } = this.state.escrowAddress
    let result = this.props.loadCallback(escrowAddress)

    let remainingTimeToReclaim = this.props.remainingTimeToReclaimCallback()
    console.log(remainingTimeToReclaim)

    this.setState({ remainingTimeToReclaim })

    console.log(result)
  }

  onReclaimFundsButtonClick = e => {
    e.preventDefault()
    const { escrowAddress } = this.state.escrowAddress

    this.props.reclaimFundsCallback(escrowAddress)
  }

  onReleaseFundsButtonClick = e => {
    e.preventDefault()
    const { escrowAddress } = this.state.escrowAddress

    this.props.releaseFundsCallback(escrowAddress)
  }

  onDepositArbitrationFeeFromPayeeButtonClicked = e => {
    const { escrowAddress } = this.state.escrowAddress
    e.preventDefault()

    this.props.depositArbitrationFeeFromPayeeCallback(escrowAddress)
  }

  render() {
    const { escrowAddress } = this.state
    return (
      <Container>
        <Form>
          <Form.Group controlId="escrow-address">
            <Form.Label>Escrow Address</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={escrowAddress}
              onChange={this.onEscrowAddressChange}
            />
          </Form.Group>
          <Button
            variant="primary"
            type="button"
            onClick={this.onLoadButtonClick}
          >
            Load
          </Button>
          <Button
            variant="primary"
            type="button"
            onClick={this.onReclaimFundsButtonClick}
          >
            Reclaim Funds
          </Button>
          <Button
            variant="primary"
            type="button"
            onClick={this.onReleaseFundsButtonClick}
          >
            Release Funds
          </Button>
          <Button
            variant="primary"
            type="button"
            onClick={this.onDepositArbitrationFeeFromPayeeButtonClicked}
          >
            Deposit Arbitration Fee
          </Button>
        </Form>
        <Badge pill variant="info">
          {this.state.remainingTimeToReclaim}
        </Badge>
      </Container>
    )
  }
}

export default Interact
