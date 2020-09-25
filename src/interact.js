import React from 'react'
import Container from 'react-bootstrap/Container'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Badge from 'react-bootstrap/Badge'
import ButtonGroup from 'react-bootstrap/ButtonGroup'
import Card from 'react-bootstrap/Card'
import InputGroup from 'react-bootstrap/InputGroup'

class Interact extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      escrowAddress: this.props.escrowAddress,
      remainingTimeToReclaim: 'Unassigned',
      remainingTimeToDepositArbitrationFee: 'Unassigned',
      status: 'Unassigned',
      arbitrator: 'Unassigned',
      value: 'Unassigned'
    }
  }

  async componentDidUpdate(prevProps) {
    if (this.props.escrowAddress !== prevProps.escrowAddress) {
      await this.setState({ escrowAddress: this.props.escrowAddress })
      this.updateBadges()
    }
  }

  onEscrowAddressChange = async e => {
    await this.setState({ escrowAddress: e.target.value })
    this.updateBadges()
  }

  updateBadges = async () => {
    const { escrowAddress, status } = this.state

    try {
      await this.setState({
        status: await this.props.statusCallback(escrowAddress)
      })
    } catch (e) {
      console.error(e)
      this.setState({ status: 'ERROR' })
    }

    try {
      this.setState({
        arbitrator: await this.props.arbitratorCallback(escrowAddress)
      })
    } catch (e) {
      console.error(e)
      this.setState({ arbitrator: 'ERROR' })
    }

    try {
      this.setState({ value: await this.props.valueCallback(escrowAddress) })
    } catch (e) {
      console.error(e)
      this.setState({ value: 'ERROR' })
    }

    if (Number(status) === 0)
      try {
        this.setState({
          remainingTimeToReclaim: await this.props.remainingTimeToReclaimCallback(
            escrowAddress
          )
        })
      } catch (e) {
        console.error(e)
        this.setState({ status: 'ERROR' })
      }

    if (Number(status) === 1)
      try {
        this.setState({
          remainingTimeToDepositArbitrationFee: await this.props.remainingTimeToDepositArbitrationFeeCallback(
            escrowAddress
          )
        })
      } catch (e) {
        console.error(e)
        this.setState({ status: 'ERROR' })
      }
  }

  onReclaimFundsButtonClick = async e => {
    e.preventDefault()
    const { escrowAddress } = this.state

    let arbitrator = await this.props.arbitratorCallback(escrowAddress)
    console.log(arbitrator)

    let arbitrationCost = await this.props.arbitrationCostCallback(
      arbitrator,
      ''
    )

    await this.props.reclaimFundsCallback(escrowAddress, arbitrationCost)

    this.updateBadges()
  }

  onReleaseFundsButtonClick = async e => {
    e.preventDefault()
    const { escrowAddress } = this.state

    await this.props.releaseFundsCallback(escrowAddress)
    this.updateBadges()
  }

  onDepositArbitrationFeeFromPayeeButtonClicked = async e => {
    e.preventDefault()
    const { escrowAddress } = this.state

    let arbitrator = await this.props.arbitratorCallback(escrowAddress)
    let arbitrationCost = await this.props.arbitrationCostCallback(
      arbitrator,
      ''
    )

    await this.props.depositArbitrationFeeForPayeeCallback(
      escrowAddress,
      arbitrationCost
    )

    this.updateBadges()
  }

  onInput = e => {
    console.log(e.target.files)
    this.setState({ fileInput: e.target.files[0] })
    console.log('file input')
  }

  onSubmitButtonClick = async e => {
    e.preventDefault()
    const { escrowAddress, fileInput } = this.state
    console.log('submit clicked')
    console.log(fileInput)

    var reader = new FileReader()
    reader.readAsArrayBuffer(fileInput)
    reader.addEventListener('loadend', async () => {
      const buffer = Buffer.from(reader.result)
      this.props.submitEvidenceCallback(escrowAddress, buffer)
    })
  }

  render() {
    const { escrowAddress, fileInput } = this.state
    return (
      <Container className="container-fluid d-flex h-100 flex-column">
        <Card className="h-100 my-4 text-center" style={{ width: 'auto' }}>
          <Card.Body>
            <Card.Title>Interact</Card.Title>
            <Form.Group controlId="escrow-address">
              <Form.Control
                className="text-center"
                as="input"
                rows="1"
                value={escrowAddress}
                onChange={this.onEscrowAddressChange}
              />
            </Form.Group>
            <Card.Subtitle className="mt-3 mb-1 text-muted">
              Smart Contract State
            </Card.Subtitle>

            <Badge className="m-1" pill variant="info">
              Status Code: {this.state.status}
            </Badge>
            <Badge className="m-1" pill variant="info">
              Escrow Amount in Weis: {this.state.value}
            </Badge>
            <Badge className="m-1" pill variant="info">
              Remaining Time To Reclaim Funds:{' '}
              {this.state.remainingTimeToReclaim}
            </Badge>
            <Badge className="m-1" pill variant="info">
              Remaining Time To Deposit Arbitration Fee:{' '}
              {this.state.remainingTimeToDepositArbitrationFee}
            </Badge>
            <Badge className="m-1" pill variant="info">
              Arbitrator: {this.state.arbitrator}
            </Badge>
            <ButtonGroup className="mt-3">
              <Button
                className="mr-2"
                variant="primary"
                type="button"
                onClick={this.onReleaseFundsButtonClick}
              >
                Release
              </Button>
              <Button
                className="mr-2"
                variant="secondary"
                type="button"
                onClick={this.onReclaimFundsButtonClick}
              >
                Reclaim
              </Button>
              <Button
                variant="secondary"
                type="button"
                onClick={this.onDepositArbitrationFeeFromPayeeButtonClicked}
                block
              >
                Deposit Arbitration Fee For Payee
              </Button>
            </ButtonGroup>
            <InputGroup className="mt-3">
              <div className="input-group">
                <div className="custom-file">
                  <input
                    type="file"
                    className="custom-file-input"
                    id="inputGroupFile04"
                    onInput={this.onInput}
                  />
                  <label
                    className="text-left custom-file-label"
                    htmlFor="inputGroupFile04"
                  >
                    {(fileInput && fileInput.name) || 'Choose evidence file'}
                  </label>
                </div>
                <div className="input-group-append">
                  <button
                    className="btn btn-primary"
                    type="button"
                    onClick={this.onSubmitButtonClick}
                  >
                    Submit
                  </button>
                </div>
              </div>
            </InputGroup>
          </Card.Body>
        </Card>
      </Container>
    )
  }
}

export default Interact
