## macOS Contacts

```
<key>NSContactsUsageDescription</key>
<string>App users your contacts</string>
```

### contacts.checkAuthorizationStatus()

Returns `String` - Can be one of 'Not Determined', 'Denied', 'Authorized', or 'Restricted`.

Checks the authorization status of the application to access the central Contacts store on macOS.

Return Value Descriptions: 
* 'Not Determined' - The user has not yet made a choice regarding whether the application may access contact data.
* 'Not Authorized' - The application is not authorized to access contact data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'Denied' - The user explicitly denied access to contact data for the application.
* 'Authorized' - The application is authorized to access contact data.