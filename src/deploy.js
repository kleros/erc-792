import React from 'react'
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'

class Deploy extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      amount: 1,
      payee: '0x0000000000000000000000000000000000000000',
      arbitrator: '0x0000000000000000000000000000000000000000',
      title: 'Title of the agreement',
      description: 'Write your agreement here'
    }
  }

  onAmountChange = e => {
    this.setState({ amount: e.target.value })
  }

  onPayeeChange = e => {
    this.setState({ payee: e.target.value })
  }

  onArbitratorChange = e => {
    this.setState({ arbitrator: e.target.value })
  }

  onTitleChange = e => {
    this.setState({ title: e.target.value })
  }

  onDescriptionChange = e => {
    this.setState({ description: e.target.value })
  }

  onDeployButtonClick = async e => {
    e.preventDefault()
    console.log('button clicked')
    const { amount, payee, arbitrator, title, description } = this.state
    await this.props.deployCallback(
      amount,
      payee,
      arbitrator,
      title,
      description
    )
  }
  render() {
    const { amount, payer, payee, arbitrator, title, description } = this.state

    return (
      <Container>
        <Form>
          <Form.Group controlId="amount">
            <Form.Label>Escrow Amount in Weis</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={amount}
              onChange={this.onAmountChange}
            />
          </Form.Group>
          <Form.Group controlId="payee">
            <Form.Label>Payee Address</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={payee}
              onChange={this.onPayeeChange}
            />
          </Form.Group>
          <Form.Group controlId="arbitrator">
            <Form.Label>Arbitrator Address</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={arbitrator}
              onChange={this.onArbitratorChange}
            />
          </Form.Group>
          <Form.Group controlId="title">
            <Form.Label>Title</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={title}
              onChange={this.onTitleChange}
            />
          </Form.Group>
          <Form.Group controlId="description">
            <Form.Label>Describe The Agreement</Form.Label>
            <Form.Control
              as="input"
              rows="1"
              value={description}
              onChange={this.onDescriptionChange}
            />
          </Form.Group>
          <Button
            variant="primary"
            type="button"
            onClick={this.onDeployButtonClick}
          >
            Deploy
          </Button>
        </Form>
      </Container>
    )
  }
}

export default Deploy
