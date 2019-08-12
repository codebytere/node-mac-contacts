const contacts = require('./build/Release/contacts.node')

function getContactsByName(name) {
  if (typeof name !== 'string') throw new TypeError('name must be a string')

  return contacts.getContactsByName.call(this, name)
}

function addNewContact(contact) {
  if (!contact || Object.keys(contact).length === 0) {
    throw new TypeError('contact must be a nonempty object')
  } else {
    const hasFirstName = contact.hasOwnProperty('firstName')
    const hasLastName = contact.hasOwnProperty('lastName')
    const hasNickname = contact.hasOwnProperty('nickname')
    const hasPhoneNumbers = contact.hasOwnProperty('phoneNumbers')
    const hasPostalAddresses = contact.hasOwnProperty('postalAddresses')
    const hasEmailAddresses = contact.hasOwnProperty('emailAddresses')

    if (hasFirstName && typeof contact.firstName !== 'string') throw new TypeError('firstName must be a string')
    if (hasLastName && typeof contact.lastName !== 'string') throw new TypeError('lastName must be a string')
    if (hasNickname && typeof contact.nickname !== 'string') throw new TypeError('nickname must be a string')
    if (hasPhoneNumbers && !Array.isArray(contact.phoneNumbers)) throw new TypeError('phoneNumbers must be an array')
    if (hasPostalAddresses && !Array.isArray(contact.postalAddresses)) throw new TypeError('postalAddresses must be an array')
    if (hasEmailAddresses && !Array.isArray(contact.emailAddresses)) throw new TypeError('emailAddresses must be an array')
  }

  return contacts.addNewContact.call(this, contact)
}

module.exports = {
  getAuthStatus: contacts.getAuthStatus,
  getAllContacts: contacts.getAllContacts,
  getContactsByName,
  addNewContact
}