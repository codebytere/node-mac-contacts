const contacts = require('bindings')('contacts.node')

const { EventEmitter } = require('events')

const listener = new EventEmitter()

listener.setup = () => {
  contacts.setupListener(listener.emit.bind(listener))
}

listener.remove = () => {
  contacts.removeListener()
}

listener.isListening = () => contacts.isListening()

const optionalProperties = [
  'jobTitle',
  'departmentName',
  'organizationName',
  'middleName',
  'note',
  'contactImage',
  'contactThumbnailImage',
  'instantMessageAddresses',
  'socialProfiles',
  'urlAddresses',
]

function getAllContacts(extraProperties = []) {
  if (!Array.isArray(extraProperties)) {
    throw new TypeError('extraProperties must be an array')
  }

  if (!extraProperties.every((p) => optionalProperties.includes(p))) {
    throw new TypeError(
      `properties in extraProperties must be one of ${optionalProperties.join(
        ', ',
      )}`,
    )
  }

  return contacts.getAllContacts.call(this, extraProperties)
}

function getContactsByName(name, extraProperties = []) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a string')
  }

  if (!Array.isArray(extraProperties)) {
    throw new TypeError('extraProperties must be an array')
  }

  if (!extraProperties.every((p) => optionalProperties.includes(p))) {
    throw new TypeError(
      `properties in extraProperties must be one of ${optionalProperties.join(
        ', ',
      )}`,
    )
  }

  return contacts.getContactsByName.call(this, name, extraProperties)
}

function validateContactArg(contact) {
  if (!contact || Object.keys(contact).length === 0) {
    throw new TypeError('contact must be a non-empty object')
  }

  for (const prop of [
    'firstName',
    'middleName',
    'lastName',
    'nickname',
    'jobTitle',
    'departmentName',
    'organizationName',
  ]) {
    const hasProp = contact.hasOwnProperty(prop)
    if (hasProp && typeof contact[prop] !== 'string') {
      throw new TypeError(`${prop} must be a string`)
    }
  }
  for (const prop of ['phoneNumbers', 'emailAddresses', 'urlAddresses']) {
    const hasProp = contact.hasOwnProperty(prop)
    if (hasProp && !Array.isArray(contact[prop])) {
      throw new TypeError(`${prop} must be an array`)
    }
  }

  const hasBirthday = contact.hasOwnProperty('birthday')

  if (hasBirthday) {
    const datePattern = /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/
    if (typeof contact.birthday !== 'string') {
      throw new TypeError('birthday must be a string')
    } else if (!contact.birthday.match(datePattern)) {
      throw new Error('birthday must use YYYY-MM-DD format')
    }
  }
}

function addNewContact(contact) {
  validateContactArg(contact)
  return contacts.addNewContact.call(this, contact)
}

function updateContact(contact) {
  validateContactArg(contact)
  return contacts.updateContact.call(this, contact)
}

function deleteContact(contact) {
  if (!contact || Object.keys(contact).length === 0) {
    throw new TypeError('contact must be a non-empty object')
  }

  const hasIdentifier = contact.hasOwnProperty('identifier')
  const hasName = contact.hasOwnProperty('name')

  if (hasIdentifier && typeof contact.identifier !== 'string') {
    throw new TypeError('identifier must be a string')
  }

  if (hasName && typeof contact.name !== 'string') {
    throw new TypeError('name must be a string')
  }

  return contacts.deleteContact.call(this, contact)
}

module.exports = {
  listener,
  requestAccess: contacts.requestAccess,
  getAuthStatus: contacts.getAuthStatus,
  getAllContacts,
  getContactsByName,
  addNewContact,
  deleteContact,
  updateContact,
}
