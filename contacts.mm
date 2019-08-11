#include <napi.h>
#import <Contacts/Contacts.h>

/***** HELPERS *****/

Napi::Object CreateContact(Napi::Env env, CNContact *cncontact) {
  Napi::Object contact = Napi::Object::New(env);

  contact.Set("firstName", std::string([[cncontact givenName] UTF8String]));
  contact.Set("lastName", std::string([[cncontact familyName] UTF8String]));
  contact.Set("nickname", std::string([[cncontact nickname] UTF8String]));

  // Populate phone number array
  int num_numbers = [[cncontact phoneNumbers] count];
  Napi::Array phone_numbers = Napi::Array::New(env, num_numbers);
  NSArray <CNLabeledValue<CNPhoneNumber*>*> *phoneNumbers = [cncontact phoneNumbers];
  for (int i = 0; i < num_numbers; i++) {
    CNLabeledValue<CNPhoneNumber*> *phone = [phoneNumbers objectAtIndex:i];
    CNPhoneNumber *number = [phone value];
    phone_numbers[i] = std::string([[number stringValue] UTF8String]);
  }

  contact.Set("phoneNumbers", phone_numbers);

  // Populate email address array
  int num_email_addresses = [[cncontact emailAddresses] count];
  Napi::Array email_addresses = Napi::Array::New(env, num_numbers);
  NSArray <CNLabeledValue<NSString*>*> *emailAddresses = [cncontact emailAddresses];
  for (int i = 0; i < num_email_addresses; i++) {
    CNLabeledValue<NSString*> *email_address = [emailAddresses objectAtIndex:i];
    phone_numbers[i] = std::string([[email_address value] UTF8String]);
  }

  contact.Set("emailAddresses", email_addresses);

  return contact;
}

Napi::Object GetContactByName(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Object contact = Napi::Object::New(env);

  // TODO(codebytere): IMPLEMENT

  return contact;
}

Napi::Object GetContactByPhoneNumber(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Object contact = Napi::Object::New(env);

  // TODO(codebytere): IMPLEMENT

  return contact;
}


Napi::Array GetAllContacts(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Array contacts = Napi::Array::New(env);

  CNContactStore* addressBook = [[CNContactStore alloc] init];
  NSArray *keys = @[
    CNContactGivenNameKey,
    CNContactFamilyNameKey,
    CNContactPhoneNumbersKey,
    CNContactEmailAddressesKey,
    CNContactNicknameKey,
    CNContactPostalAddressesKey,
    CNContactBirthdayKey
  ];

  NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:addressBook.defaultContainerIdentifier];
	NSArray *cncontacts = [addressBook unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:nil];
  
  int i = 0;
  for (CNContact *cncontact in cncontacts) {
    contacts[i++] = CreateContact(env, cncontact);
	}

  return contacts;
}

Napi::Value GetAuthStatus(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  std::string auth_status = "Not Determined";

  CNEntityType entityType = CNEntityTypeContacts;
  auto status_for_entity = [CNContactStore authorizationStatusForEntityType:entityType];

  if (status_for_entity == CNAuthorizationStatusAuthorized)
    auth_status = "Authorized";
  else if (status_for_entity == CNAuthorizationStatusDenied)
    auth_status = "Denied";
  else if (status_for_entity == CNAuthorizationStatusRestricted)
    auth_status = "Restricted";

  return Napi::Value::From(env, auth_status);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "getAllContacts"), Napi::Function::New(env, GetAllContacts));
  exports.Set(Napi::String::New(env, "getAuthStatus"), Napi::Function::New(env, GetAuthStatus));
  return exports;
}

NODE_API_MODULE(contacts, Init)