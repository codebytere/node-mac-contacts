const { expect } = require('chai')
const { 
  getAuthStatus,
  getContactsByName,
  getAllContacts,
  addNewContact,
  deleteContact,
  updateContact
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

  describe('getContactsByName(name[, extraProperties])', () => {
    it('should throw if name is not a string', () => {
      expect(() => {
        getContactsByName(12345)
      }).to.throw(/name must be a string/)
    })

    it('should throw if extraProperties is not an array', () => {
      expect(() => {
        getContactsByName('jim-bob', 12345)
      }).to.throw(/extraProperties must be an array/)
    })
  })

  describe('getAllContacts([extraProperties])', () => {
    it('should return an array', () => {
      const contacts = getAllContacts()
      expect(contacts).to.be.an('array')
    })

    it('should throw if extraProperties is not an array', () => {
      expect(() => {
        getAllContacts('tsk-bad-array')
      }).to.throw(/extraProperties must be an array/)
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

  describe('deleteContact(name)', () => {
    it('should throw if name is not a string', () => {
      expect(() => {
        deleteContact(12345)
      }).to.throw(/name must be a string/)
    })
  })

  describe('updateContact(contact)', () => {
    it('throws if contact is not a nonempty object', () => {
      expect(() => {
        updateContact(1)
      }).to.throw(/contact must be a non-empty object/)

      expect(() => {
        updateContact({})
      }).to.throw(/contact must be a non-empty object/)
    })

    it('should throw if name properties are not strings', () => {
      expect(() => {
        updateContact({ firstName: 1 })
      }).to.throw(/firstName must be a string/)

      expect(() => {
        updateContact({ lastName: 1 })
      }).to.throw(/lastName must be a string/)

      expect(() => {
        updateContact({ nickname: 1 })
      }).to.throw(/nickname must be a string/)
    })

    it('should throw if birthday is not a string in YYYY-MM-DD format', () => {
      expect(() => {
        updateContact({ birthday: 1 })
      }).to.throw(/birthday must be a string/)

      expect(() => {
        updateContact({ birthday: '01-01-1970' })
      }).to.throw(/birthday must use YYYY-MM-DD format/)
    })

    it('should throw if phoneNumbers is not an array', () => {
      expect(() => {
        updateContact({ phoneNumbers: 1 })
      }).to.throw(/phoneNumbers must be an array/)
    })

    it('should throw if emailAddresses is not an array', () => {
      expect(() => {
        updateContact({ emailAddresses: 1 })
      }).to.throw(/emailAddresses must be an array/)
    })
  })
})