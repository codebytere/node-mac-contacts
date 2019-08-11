#include <napi.h>
#import <Contacts/Contacts.h>

/***** HELPERS *****/

Napi::Object CreateContact(Napi::Env env, CNContact *cncontact) {
  Napi::Object contact = Napi::Object::New(env);

  contact.Set("firstName", std::string([[cncontact givenName] UTF8String]));
  contact.Set("lastName", std::string([[cncontact familyName] UTF8String]));

  return contact;
}

Napi::Array GetAllContacts(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Array contacts = Napi::Array::New(env);

  CNContactStore* addressBook = [[CNContactStore alloc] init];
  NSArray *keys = @[ CNContactGivenNameKey, CNContactFamilyNameKey ];

  NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:addressBook.defaultContainerIdentifier];
	NSArray *cncontacts = [addressBook unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:nil];
  
  int i = 0;
  for (CNContact *cncontact in cncontacts) {
    contacts[i++] = CreateContact(env, cncontact);;
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