## macOS Contacts

This Native Node Module allows you to create, read, update, and delete contact from users' contacts databases on macOS.

All methods invoking the [CNContactStore](https://developer.apple.com/documentation/contacts/cncontactstore) will require authorization, which will be requested the first time the functions themselves are invoked. You can verify authorization status with `contacts.checkAuthorizationStatus()` as outlined below.

In your app, you should put the reason you're requesting to manipulate user's contacts database in your `Info.plist` like so:

```
<key>NSContactsUsageDescription</key>
<string>Your reason for wanting to access the Contact store</string>
```

### contacts.checkAuthorizationStatus()

Returns `String` - Can be one of 'Not Determined', 'Denied', 'Authorized', or 'Restricted'.

Checks the authorization status of the application to access the central Contacts store on macOS.

Return Value Descriptions: 
* 'Not Determined' - The user has not yet made a choice regarding whether the application may access contact data.
* 'Not Authorized' - The application is not authorized to access contact data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'Denied' - The user explicitly denied access to contact data for the application.
* 'Authorized' - The application is authorized to access contact data.

```js
const authStatus = contacts.getAuthStatus()

console.log(`Authorization access to contacts is: ${authStatus}`)
/* prints one of:
'Not Determined'
'Denied',
'Authorized'
'Restricted'
*/
```

### contacts.getAllContacts()

Returns `Array<Object>` - Returns an array of contact objects.

```js
const allContacts = contacts.getAllContacts()

console.log(allContacts[0])
/* prints
[
  { 
    firstName: 'Jonathan',
    lastName: 'Appleseed',
    nickname: 'Johnny',
    phoneNumbers: [ +11234566789' ],
    emailAddresses: [ 'johnny@appleseed.com' ] 
    postalAddresses: [ '123 Pine Tree Way\nBlack Oak, Arkansas 72414\nUnited States' ] 
  }
]
*/
```

This method will return an empty array (`[]`) if access to Contacts has not been granted.

### contacts.getContactsByName(name)

* `name` String - The first or last name of a contact.

Returns `Array<Object>` - Returns an array of contact objects where either the first or last name of the contact matches `name`.

```js
const contacts = contacts.getContactsByName('Appleseed')

console.log(contacts)
/* prints
[
  { 
    firstName: 'Jonathan',
    lastName: 'Appleseed',
    nickname: 'Johnny',
    phoneNumbers: [ +11234566789' ],
    emailAddresses: [ 'johnny@appleseed.com' ] 
    postalAddresses: [ '123 Pine Tree Way\nBlack Oak, Arkansas 72414\nUnited States' ] 
  }
]
*/
```

This method will return an empty array (`[]`) if access to Contacts has not been granted.

### contacts.addNewContact(contact)

* `contact` Object
  * `firstName` String - The first name of the contact.
  * `lastName` String - The last name of the contact.
  * `nickname` String - The nickname for the contact.
  * `lastName` Array<String> - The phone numbers for the contact, as strings in [E.164 format](https://en.wikipedia.org/wiki/E.164): `+14155552671` or `+442071838750`.
  * `lastName` Array<String> - The email addresses for the contact, as strings.
  * `lastName` Array<String> - The postal addresses for the contact, as strings.

Returns `Boolean` - whether the contact information was created successfully.

Creates and save a new contact to the user's contacts database.

```js
const contact = { firstName: 'Bilbo', lastName: 'Baggins' }
const success = contacts.addNewContact(contact)
console.log(`New contact was ${success ? 'saved' : 'not saved'}.`)
```

This method will return `false` if access to Contacts has not been granted.
