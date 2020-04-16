const {
  getContactsByName,
  getAllContacts
} = require('./index')

const contacts = getAllContacts(['contactImage'])

console.log(contacts[0])