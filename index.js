const contacts = require('bindings')('contacts.node')

function getAllContacts(extraProperties = []) {
  if (Array.isArray(extraProperties)) {
    throw new TypeError('extraProperties must be an array')
  }

  return contacts.getAllContacts.call(this, extraProperties)
}

function getContactsByName(name, extraProperties = []) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a string')
  }

  if (Array.isArray(extraProperties)) {
    throw new TypeError('extraProperties must be an array')
  }

  return contacts.getContactsByName.call(this, name, extraProperties)
}

function addNewContact(contact) {
  if (!contact || Object.keys(contact).length === 0) {
    throw new TypeError('contact must be a non-empty object')
  } else {
    const hasFirstName = contact.hasOwnProperty('firstName')
    const hasLastName = contact.hasOwnProperty('lastName')
    const hasNickname = contact.hasOwnProperty('nickname')
    const hasBirthday = contact.hasOwnProperty('birthday')
    const hasPhoneNumbers = contact.hasOwnProperty('phoneNumbers')
    const hasEmailAddresses = contact.hasOwnProperty('emailAddresses')

    if (hasFirstName && typeof contact.firstName !== 'string') {
      throw new TypeError('firstName must be a string')
    }

    if (hasLastName && typeof contact.lastName !== 'string') {
      throw new TypeError('lastName must be a string')
    }

    if (hasNickname && typeof contact.nickname !== 'string') {
      throw new TypeError('nickname must be a string')
    }

    if (hasPhoneNumbers && !Array.isArray(contact.phoneNumbers)) {
      throw new TypeError('phoneNumbers must be an array')
    }

    if (hasEmailAddresses && !Array.isArray(contact.emailAddresses)) {
      throw new TypeError('emailAddresses must be an array')
    }

    if (hasBirthday) {
      const datePattern = /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/
      if (typeof contact.birthday !== 'string') {
        throw new TypeError('birthday must be a string')
      } else if (!contact.birthday.match(datePattern)) {
        throw new Error('birthday must use YYYY-MM-DD format')
      }
    }
  }

  return contacts.addNewContact.call(this, contact)
}

function updateContact(contact) {
  if (!contact || Object.keys(contact).length === 0) {
    throw new TypeError('contact must be a non-empty object')
  } else {
    const hasFirstName = contact.hasOwnProperty('firstName')
    const hasLastName = contact.hasOwnProperty('lastName')
    const hasNickname = contact.hasOwnProperty('nickname')
    const hasBirthday = contact.hasOwnProperty('birthday')
    const hasPhoneNumbers = contact.hasOwnProperty('phoneNumbers')
    const hasEmailAddresses = contact.hasOwnProperty('emailAddresses')

    if (hasFirstName && typeof contact.firstName !== 'string') {
      throw new TypeError('firstName must be a string')
    }

    if (hasLastName && typeof contact.lastName !== 'string') {
      throw new TypeError('lastName must be a string')
    }

    if (hasNickname && typeof contact.nickname !== 'string') {
      throw new TypeError('nickname must be a string')
    }

    if (hasPhoneNumbers && !Array.isArray(contact.phoneNumbers)) {
      throw new TypeError('phoneNumbers must be an array')
    }

    if (hasEmailAddresses && !Array.isArray(contact.emailAddresses)) {
      throw new TypeError('emailAddresses must be an array')
    }

    if (hasBirthday) {
      const datePattern = /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/
      if (typeof contact.birthday !== 'string') {
        throw new TypeError('birthday must be a string')
      } else if (!contact.birthday.match(datePattern)) {
        throw new Error('birthday must use YYYY-MM-DD format')
      }
    }
  }

  return contacts.updateContact.call(this, contact)
}

function deleteContact(name) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a string')
  }

  return contacts.deleteContact.call(this, name)
}

module.exports = {
  getAuthStatus: contacts.getAuthStatus,
  getAllContacts,
  getContactsByName,
  addNewContact,
  deleteContact,
  updateContact,
}
