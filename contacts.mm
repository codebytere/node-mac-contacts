#include <napi.h>
#import <Contacts/Contacts.h>

struct Contact {
  Napi::String first_name;
  Napi::String last_name;
  Napi::String job_title;
  Napi::String nickname;
  Napi::String birthday;
  Napi::Array phone_numbers;
  Napi::Array postal_addresses;
  Napi::Array email_addresses;
};

// getAllContacts()
Napi::Array GetAllContacts(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  CNContactStore* addressBook = [[CNContactStore alloc] init];
  Napi::Array companies = Napi::Array::New(env, 6);
  return companies;
}


// getAuthStatus()
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
  exports.Set(
    Napi::String::New(env, "getAllContacts"),
    Napi::Function::New(env, GetAllContacts)
  );

  exports.Set(
    Napi::String::New(env, "getAuthStatus"),
    Napi::Function::New(env, GetAuthStatus)
  );

  return exports;
}

NODE_API_MODULE(contacts, Init)