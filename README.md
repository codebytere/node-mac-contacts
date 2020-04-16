[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)
 [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com) [![Actions Status](https://github.com/codebytere/node-mac-contacts/workflows/Test/badge.svg)](https://github.com/codebytere/node-mac-contacts/actions)

# node-mac-contacts

## Description

```js
$ npm i node-mac-contacts
```

This Native Node Module allows you to create, read, update, and delete contact from users' contacts databases on macOS.

All methods invoking the [CNContactStore](https://developer.apple.com/documentation/contacts/cncontactstore) will require authorization, which will be requested the first time the functions themselves are invoked. You can verify authorization status with `contacts.getAuthStatus()` as outlined below.

In your app, you should put the reason you're requesting to manipulate user's contacts database in your `Info.plist` like so:

```
<key>NSContactsUsageDescription</key>
<string>Your reason for wanting to access the Contact store</string>
```

## API

### contacts.getAuthStatus()

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

### contacts.getAllContacts([extraProperties])

* `extraProperties` string[] (optional) - an array of extra contact properties to fetch that can be any of: `jobTitle`, `departmentName`, `organizationName`, `middleName`, `note`, `contactImage`, `contactThumbnailImage`, or `socialProfiles`.

Returns `Array<Object>` - Returns an array of contact objects.

The returned objects will take the following format:

* `firstName` String - The contact's first name, or an empty string ('') if one is not set.
* `lastName` String - The contact's last name, or an empty string ('') if one is not set.
* `nickname` String - The contact's nickname, or an empty string ('') if one is not set.
* `birthday` String - The contact's birthday in YYYY-MM-DD format, or an empty string ('') if one is not set.
* `phoneNumbers` String[] - An array of phone numbers as strings in [E.164 format](https://en.wikipedia.org/wiki/E.164).
* `emailAddresses` String[] - An array of email addresses as strings.
* `postalAddresses` String[] - An array of postal as strings.
* `jobTitle` String (optional) - The contact's job title.
* `departmentName` String (optional) - The name of the department associated with the contact.
* `organizationName`  String (optional) - The name of the organization associated with the contact.
* `middleName` String (optional) - The contact's middle name.
* `note` String (optional) - The note associated with the contact.
* `contactImage` Buffer (optional) - a Buffer representation of the contact's profile picture.
* `contactThumbnailImage` Buffer (optional) - a Buffer representation of The thumbnail version of the contact’s profile picture.
* `socialProfiles` Object[] (optional) - An array of labeled social profiles for a contact.

This method will return an empty array (`[]`) if access to Contacts has not been granted.

Example:

```js
const allContacts = contacts.getAllContacts()

console.log(allContacts[0])
/* Prints:
[
  { 
    firstName: 'Jonathan',
    lastName: 'Appleseed',
    nickname: 'Johnny',
    birthday: '1970-01-01',
    phoneNumbers: [ +11234566789' ],
    emailAddresses: [ 'johnny@appleseed.com' ],
    postalAddresses: [ '123 Pine Tree Way\nBlack Oak, Arkansas 72414\nUnited States' ]
  }
]
*/
```

### contacts.getContactsByName(name[, extraProperties])

* `extraProperties` string[] (optional) - an array of extra contact properties to fetch that can be any of: `jobTitle`, `departmentName`, `organizationName`, `middleName`, `note`, `contactImage`, `contactThumbnailImage`, or `socialProfiles`.

Returns `Array<Object>` - Returns an array of contact objects where either the first or last name of the contact matches `name`.

If a contact's full name is 'Shelley Vohr', I could pass 'Shelley', 'Vohr', or 'Shelley Vohr' as `name`.

The returned object will take the following format:

* `firstName` String - The contact's first name, or an empty string ('') if one is not set.
* `lastName` String - The contact's last name, or an empty string ('') if one is not set.
* `nickname` String - The contact's nickname, or an empty string ('') if one is not set.
* `birthday` String - The contact's birthday in YYYY-MM-DD format, or an empty string ('') if one is not set.
* `phoneNumbers` String[] - An array of phone numbers as strings in [E.164 format](https://en.wikipedia.org/wiki/E.164).
* `emailAddresses` String[] - An array of email addresses as strings.
* `postalAddresses` String[] - An array of postal as strings.
* `jobTitle` String (optional) - The contact's job title.
* `departmentName` String (optional) - The name of the department associated with the contact.
* `organizationName`  String (optional) - The name of the organization associated with the contact.
* `middleName` String (optional) - The contact's middle name.
* `note` String (optional) - The note associated with the contact.
* `contactImage` Buffer (optional) - a Buffer representation of the contact's profile picture.
* `contactThumbnailImage` Buffer (optional) - a Buffer representation of The thumbnail version of the contact’s profile picture.
* `socialProfiles` Object[] (optional) - An array of labeled social profiles for a contact.

This method will return an empty array (`[]`) if access to Contacts has not been granted.

Example:

```js
const contacts = contacts.getContactsByName('Appleseed')

console.log(contacts)
/* Prints:
[
  { 
    firstName: 'Jonathan',
    lastName: 'Appleseed',
    nickname: 'Johnny',
    birthday: '1970-01-01',
    phoneNumbers: [ +11234566789' ],
    emailAddresses: [ 'johnny@appleseed.com' ],
    postalAddresses: [ '123 Pine Tree Way\nBlack Oak, Arkansas 72414\nUnited States' ]
  }
]
*/
```

### contacts.addNewContact(contact)

* `contact` Object
  * `firstName` String (required) - The first name of the contact.
  * `lastName` String (optional) - The last name of the contact.
  * `nickname` String (optional) - The nickname for the contact.
  * `birthday` String (optional) - The birthday for the contact in `YYYY-MM-DD` format.
  * `phoneNumbers` Array\<String\> (optional) - The phone numbers for the contact, as strings in [E.164 format](https://en.wikipedia.org/wiki/E.164): `+14155552671` or `+442071838750`.
  * `emailAddresses` Array\<String\> (optional) - The email addresses for the contact, as strings.

Returns `Boolean` - whether the contact information was created successfully.

Creates and save a new contact to the user's contacts database. 

This method will return `false` if access to Contacts has not been granted.

Example:

```js
const success = contacts.addNewContact({
  firstName: 'William',
  lastName: 'Grapeseed',
  nickname: 'Billy',
  birthday: '1990-09-09',
  phoneNumbers: [ '+1234567890' ],
  emailAddresses: ['billy@grapeseed.com' ]
})

console.log(`New contact was ${success ? 'saved' : 'not saved'}.`)
```

### contacts.deleteContact(name)

* `name` String (required) - The first, last, or full name of a contact.

Returns `Boolean` - whether the contact was deleted successfully.

Deletes a contact to the user's contacts database.

If a contact's full name is 'Shelley Vohr', I could pass 'Shelley', 'Vohr', or 'Shelley Vohr' as `name`.
However, you should take care to specify `name` to such a degree that you can be confident the first contact to be returned from a predicate search is the contact you intend to delete.

This method will return `false` if access to Contacts has not been granted.

Example:

```js
const name = 'Jonathan Appleseed'
const deleted = contacts.deleteContact(name)

console.log(`Contact ${name} was ${deleted ? 'deleted' : 'not deleted'}.`)
```

### contacts.updateContact(contact)

* `contact` Object
  * `firstName` String (required) - The first name of the contact.
  * `lastName` String (optional) - The last name of the contact.
  * `nickname` String (optional) - The nickname for the contact.
  * `birthday` String (optional) - The birthday for the contact in `YYYY-MM-DD` format.
  * `phoneNumbers` Array\<String\> (optional) - The phone numbers for the contact, as strings in [E.164 format](https://en.wikipedia.org/wiki/E.164): `+14155552671` or `+442071838750`.
  * `emailAddresses` Array\<String\> (optional) - The email addresses for the contact, as strings.

Returns `Boolean` - whether the contact was updated successfully.

Updates a contact to the user's contacts database.

You should take care to specify parameters to the `contact` object to such a degree that you can be confident the first contact to be returned from a predicate search is the contact you intend to update.

This method will return `false` if access to Contacts has not been granted.

Example:

```js
// Change contact's nickname from Billy -> Will
const updated = contacts.updateContact({
  firstName: 'William',
  lastName: 'Grapeseed',
  nickname: 'Will'
})

console.log(`Contact was ${updated ? 'updated' : 'not updated'}.`)
```
