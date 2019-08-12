## macOS Contacts

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

### contacts.getAllContacts()

Returns `Array<Object>` - Returns an array of contact objects.

Each contact object contains the following:

```js
{ 
  firstName: 'Jonathan',
  lastName: 'Appleseed',
  nickname: 'Johnny',
  phoneNumbers: [
    '(123) 456-6789',
    '+1122334455678'
  ],
  emailAddresses: [
    'johnny@appleseed.com'
  ] 
}
```

### contacts.getContactsByName(name)

* `name` String - The first or last name of a contact.

Returns `Array<Object>` - Returns an array of contact objects where either the first or last name of the contact matches `name`.

Each contact object contains the following:

```js
{ 
  firstName: 'Jonathan',
  lastName: 'Appleseed',
  nickname: 'Johnny',
  phoneNumbers: [
    '(123) 456-6789',
    '+1122334455678'
  ],
  emailAddresses: [
    'johnny@appleseed.com'
  ] 
}
```