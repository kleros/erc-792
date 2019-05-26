export default (payer, payee, amount, title, description) => ({
  category: 'Escrow',
  title: title,
  description: description,
  question: 'Does payer deserves to be refunded?',
  rulingOptions: {
    type: 'single-select',
    titles: ['Refund the Payer', 'Pay the Payee'],
    descriptions: [
      'Select to return funds to the payer',
      'Select to release funds to the payee'
    ]
  },
  aliases: {
    [payer]: 'payer',
    [payee]: 'payee'
  },
  amount
})
