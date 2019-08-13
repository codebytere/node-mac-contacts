const { expect } = require('chai')
const { 
  getAuthStatus,
  getContactsByName,
  getAllContacts,
  addNewContact
} = require('../index')

describe('node-mac-contacts', () => {
  describe('getAuthStatus()', () => {
    it('should not throw', () => {
      expect(() => { getAuthStatus() }).to.not.throw()
    })

    it('should return a string', () => {
      const status = getAuthStatus()
      expect(status).to.be.a('string')
    })
  })

  describe('getContactsByName(name)', () => {
    it('should throw if name is not a string', () => {
      expect(() => {
        getContactsByName(12345)
      }).to.throw(/name must be a string/)
    })
  })

  describe('getAllContacts()', () => {
    it('should return an array', () => {
      const contacts = getAllContacts()
      expect(contacts).to.be.an('array')
    })
  })

  describe('addNewContact(contact)', () => {
    it('throws if contact is not a nonempty object', () => {
      expect(() => {
        addNewContact(1)
      }).to.throw(/contact must be a non-empty object/)

      expect(() => {
        addNewContact({})
      }).to.throw(/contact must be a non-empty object/)
    })

    it('should throw if name properties are not strings', () => {
      expect(() => {
        addNewContact({ firstName: 1 })
      }).to.throw(/firstName must be a string/)

      expect(() => {
        addNewContact({ lastName: 1 })
      }).to.throw(/lastName must be a string/)

      expect(() => {
        addNewContact({ nickname: 1 })
      }).to.throw(/nickname must be a string/)
    })

    it('should throw if birthday is not a string in YYYY-MM-DD format', () => {
      expect(() => {
        addNewContact({ birthday: 1 })
      }).to.throw(/birthday must be a string/)

      expect(() => {
        addNewContact({ birthday: '01-01-1970' })
      }).to.throw(/birthday must use YYYY-MM-DD format/)
    })

    it('should throw if phoneNumbers is not an array', () => {
      expect(() => {
        addNewContact({ phoneNumbers: 1 })
      }).to.throw(/phoneNumbers must be an array/)
    })

    it('should throw if emailAddresses is not an array', () => {
      expect(() => {
        addNewContact({ emailAddresses: 1 })
      }).to.throw(/emailAddresses must be an array/)
    })
  })
})