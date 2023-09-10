const { expect } = require('chai')
const {
  getAuthStatus,
  getContactsByName,
  getAllContacts,
  addNewContact,
  deleteContact,
  updateContact,
  listener,
  requestAccess,
} = require('../index')

const isCI = require('is-ci')
const ifit = (condition) => (condition ? it : it.skip)
const ifdescribe = (condition) => (condition ? describe : describe.skip)

if (!isCI) {
  requestAccess().then((status) => {
    if (status !== 'Authorized') {
      console.error('Access to Contacts not authorized - cannot proceed.')
      process.exit(1)
    }
  })
}

describe('node-mac-contacts', () => {
  describe('getAuthStatus()', () => {
    it('should not throw', () => {
      expect(() => {
        getAuthStatus()
      }).to.not.throw()
    })

    it('should return a string', () => {
      const status = getAuthStatus()
      expect(status).to.be.a('string')
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

    it('should throw if extraProperties contains invalid properties', () => {
      const errorMessage =
        'properties in extraProperties must be one of jobTitle, departmentName, organizationName, middleName, note, contactImage, contactThumbnailImage, instantMessageAddresses, socialProfiles, urlAddresses'

      expect(() => {
        getAllContacts(['bad-property'])
      }).to.throw(errorMessage)
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

    ifit(!isCI)('should successfully add a contact', () => {
      const success = addNewContact({
        firstName: 'William',
        lastName: 'Grapeseed',
        nickname: 'Billy',
        birthday: '1990-09-09',
        phoneNumbers: ['+1234567890'],
        emailAddresses: ['billy@grapeseed.com'],
      })

      expect(success).to.be.true
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

    it('should throw if extraProperties contains invalid properties', () => {
      const errorMessage =
        'properties in extraProperties must be one of jobTitle, departmentName, organizationName, middleName, note, contactImage, contactThumbnailImage, instantMessageAddresses, socialProfiles, urlAddresses'

      expect(() => {
        getContactsByName('jim-bob', ['bad-property'])
      }).to.throw(errorMessage)
    })

    ifit(!isCI)('should retrieve a contact by name predicates', () => {
      addNewContact({
        firstName: 'Sherlock',
        lastName: 'Holmes',
        nickname: 'Sherllock',
        birthday: '1854-01-06',
        phoneNumbers: ['+1234567890'],
        emailAddresses: ['sherlock@holmes.com'],
      })

      const contacts = getContactsByName('Sherlock Holmes')
      expect(contacts).to.be.an('array').of.length.gte(1)

      const contact = contacts[0]
      expect(contact.firstName).to.eql('Sherlock')
    })
  })

  describe('deleteContact({ name, identifier })', () => {
    it('should throw if name is not a string', () => {
      expect(() => {
        deleteContact({ name: 12345 })
      }).to.throw(/name must be a string/)
    })
    it('should throw if identifier is not a string', () => {
      expect(() => {
        deleteContact({ identifier: 12345 })
      }).to.throw(/identifier must be a string/)
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

  ifdescribe(!isCI)('listener', () => {
    afterEach(() => {
      if (listener.isListening()) {
        listener.remove()
      }
    })

    it('throws when trying to remove a nonexistent listener', () => {
      expect(() => {
        listener.remove()
      }).to.throw(/No observers are currently observing/)
    })

    it('throws when trying to setup an already-existent listener', () => {
      expect(() => {
        listener.setup()
        listener.setup()
      }).to.throw(/An observer is already observing/)
    })

    it('emits an event when the contact is changed', (done) => {
      listener.setup()

      addNewContact({
        firstName: 'William',
        lastName: 'Grapeseed',
        nickname: 'Billy',
        birthday: '1990-09-09',
        phoneNumbers: ['+1234567890'],
        emailAddresses: ['billy@grapeseed.com'],
      })

      listener.once('contact-changed', () => {
        done()
      })
    })
  })
})
