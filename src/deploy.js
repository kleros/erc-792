import React from 'react'
import Container from 'react-bootstrap/Container'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'

class Deploy extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      amount: '',
      payee: '',
      arbitrator: '',
      title: '',
      description: ''
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
    const { amount, payee, arbitrator, title, description } = this.state
    console.log(arbitrator)
    await this.props.deployCallback(
      amount,
      payee,
      arbitrator,
      title,
      description
    )
  }
  render() {
    const { amount, payee, arbitrator, title, description } = this.state

    return (
      <Container>
        <Card className="my-4 text-center " style={{ width: 'auto' }}>
          <Card.Body>
            <Card.Title>Deploy</Card.Title>
            <Form>
              <Form.Group controlId="amount">
                <Form.Control
                  as="input"
                  rows="1"
                  value={amount}
                  onChange={this.onAmountChange}
                  placeholder={'Escrow Amount in Weis'}
                />
              </Form.Group>
              <Form.Group controlId="payee">
                <Form.Control
                  as="input"
                  rows="1"
                  value={payee}
                  onChange={this.onPayeeChange}
                  placeholder={'Payee Address'}
                />
              </Form.Group>
              <Form.Group controlId="arbitrator">
                <Form.Control
                  as="input"
                  rows="1"
                  value={arbitrator}
                  onChange={this.onArbitratorChange}
                  placeholder={'Arbitrator Address'}
                />
              </Form.Group>
              <Form.Group controlId="title">
                <Form.Control
                  as="input"
                  rows="1"
                  value={title}
                  onChange={this.onTitleChange}
                  placeholder={'Title'}
                />
              </Form.Group>
              <Form.Group controlId="description">
                <Form.Control
                  as="input"
                  rows="1"
                  value={description}
                  onChange={this.onDescriptionChange}
                  placeholder={'Describe The Agreement'}
                />
              </Form.Group>
              <Button
                variant="primary"
                type="button"
                onClick={this.onDeployButtonClick}
                block
              >
                Deploy
              </Button>
            </Form>
          </Card.Body>
        </Card>
      </Container>
    )
  }
}

export default Deploy
