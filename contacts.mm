#import <Contacts/Contacts.h>
#include <napi.h>

Napi::ThreadSafeFunction ts_fn;
id observer;

/***** HELPERS *****/

// Parses and returns an array of email addresses as strings.
Napi::Array GetEmailAddresses(Napi::Env env, CNContact *cncontact) {
  int num_email_addresses = [[cncontact emailAddresses] count];

  Napi::Array email_addresses = Napi::Array::New(env, num_email_addresses);
  NSArray<CNLabeledValue<NSString *> *> *emailAddresses =
      [cncontact emailAddresses];
  for (int i = 0; i < num_email_addresses; i++) {
    CNLabeledValue<NSString *> *email_address =
        [emailAddresses objectAtIndex:i];
    email_addresses[i] = std::string([[email_address value] UTF8String]);
  }

  return email_addresses;
}

// Parses and returns an array of phone numbers as strings.
Napi::Array GetPhoneNumbers(Napi::Env env, CNContact *cncontact) {
  int num_phone_numbers = [[cncontact phoneNumbers] count];

  Napi::Array phone_numbers = Napi::Array::New(env, num_phone_numbers);
  NSArray<CNLabeledValue<CNPhoneNumber *> *> *phoneNumbers =
      [cncontact phoneNumbers];
  for (int i = 0; i < num_phone_numbers; i++) {
    CNLabeledValue<CNPhoneNumber *> *phone = [phoneNumbers objectAtIndex:i];
    CNPhoneNumber *number = [phone value];
    phone_numbers[i] = std::string([[number stringValue] UTF8String]);
  }

  return phone_numbers;
}

// Parses and returns an array of postal addresses as strings.
Napi::Array GetPostalAddresses(Napi::Env env, CNContact *cncontact) {
  int num_postal_addresses = [[cncontact postalAddresses] count];
  Napi::Array postal_addresses = Napi::Array::New(env, num_postal_addresses);

  CNPostalAddressFormatter *formatter = [[CNPostalAddressFormatter alloc] init];
  NSArray *postalAddresses =
      (NSArray *)[[cncontact postalAddresses] valueForKey:@"value"];
  for (int i = 0; i < num_postal_addresses; i++) {
    CNPostalAddress *address = [postalAddresses objectAtIndex:i];
    NSString *addr_string = [formatter stringFromPostalAddress:address];
    postal_addresses[i] = std::string([addr_string UTF8String]);
  }

  return postal_addresses;
}

// Parses and returns an array of social profiles as objects.
Napi::Array GetSocialProfiles(Napi::Env env, CNContact *cncontact) {
  int num_social_profiles = [[cncontact socialProfiles] count];
  Napi::Array social_profiles = Napi::Array::New(env, num_social_profiles);

  NSArray *profiles =
      (NSArray *)[[cncontact socialProfiles] valueForKey:@"value"];
  for (int i = 0; i < num_social_profiles; i++) {
    Napi::Object profile = Napi::Object::New(env);
    CNSocialProfile *social_profile = [profiles objectAtIndex:i];

    profile.Set("service",
                std::string([social_profile service]
                                ? [[social_profile service] UTF8String]
                                : ""));
    profile.Set("username",
                std::string([social_profile username]
                                ? [[social_profile username] UTF8String]
                                : ""));
    profile.Set("url", std::string([social_profile urlString]
                                       ? [[social_profile urlString] UTF8String]
                                       : ""));

    social_profiles[i] = profile;
  }

  return social_profiles;
}

// Parses and returns an array of instant message addresses as objects.
Napi::Array GetInstantMessageAddresses(Napi::Env env, CNContact *cncontact) {
  int num_im_addresses = [[cncontact instantMessageAddresses] count];
  Napi::Array im_addresses = Napi::Array::New(env, num_im_addresses);

  NSArray *addresses =
      (NSArray *)[[cncontact instantMessageAddresses] valueForKey:@"value"];
  for (int i = 0; i < num_im_addresses; i++) {
    Napi::Object address = Napi::Object::New(env);
    CNSocialProfile *im_address = [addresses objectAtIndex:i];

    address.Set("service", std::string([im_address service]
                                           ? [[im_address service] UTF8String]
                                           : ""));
    address.Set("username", std::string([im_address username]
                                            ? [[im_address username] UTF8String]
                                            : ""));

    im_addresses[i] = address;
  }

  return im_addresses;
}

// Parses and returns birthdays as strings in YYYY-MM-DD format.
std::string GetBirthday(CNContact *cncontact) {
  std::string result;

  NSDate *birth_date = [[cncontact birthday] date];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd"];

  NSString *birthday = [formatter stringFromDate:birth_date];
  if (birthday)
    result = std::string([birthday UTF8String]);

  return result;
}

Napi::Buffer<uint8_t> GetContactImage(Napi::Env env, CNContact *cncontact,
                                      bool thumbnail) {
  std::vector<uint8_t> data;

  NSData *image_data =
      thumbnail ? [cncontact thumbnailImageData] : [cncontact imageData];
  const uint8 *bytes = (uint8 *)[image_data bytes];
  data.assign(bytes, bytes + [image_data length]);

  if (data.empty())
    return Napi::Buffer<uint8_t>::New(env, 0);
  return Napi::Buffer<uint8_t>::Copy(env, &data[0], data.size());
}

// Creates an object containing all properties of a macOS contact.
Napi::Object CreateContact(Napi::Env env, CNContact *cncontact) {
  Napi::Object contact = Napi::Object::New(env);

  // Default contact properties.

  contact.Set("identifier", std::string([[cncontact identifier] UTF8String]));

  contact.Set("firstName", std::string([[cncontact givenName] UTF8String]));
  contact.Set("lastName", std::string([[cncontact familyName] UTF8String]));
  contact.Set("nickname", std::string([[cncontact nickname] UTF8String]));

  std::string birthday = GetBirthday(cncontact);
  contact.Set("birthday", birthday.empty() ? "" : birthday);

  Napi::Array phone_numbers = GetPhoneNumbers(env, cncontact);
  contact.Set("phoneNumbers", phone_numbers);

  Napi::Array email_addresses = GetEmailAddresses(env, cncontact);
  contact.Set("emailAddresses", email_addresses);

  Napi::Array postal_addresses = GetPostalAddresses(env, cncontact);
  contact.Set("postalAddresses", postal_addresses);

  // Optional contact properties.

  if ([cncontact isKeyAvailable:CNContactImageDataKey]) {
    Napi::Buffer<uint8_t> image_buffer = GetContactImage(env, cncontact, false);
    contact.Set("contactImage", image_buffer);
  }

  if ([cncontact isKeyAvailable:CNContactThumbnailImageDataKey]) {
    Napi::Buffer<uint8_t> image_buffer = GetContactImage(env, cncontact, true);
    contact.Set("contactThumbnailImage", image_buffer);
  }

  if ([cncontact isKeyAvailable:CNContactJobTitleKey])
    contact.Set("jobTitle", std::string([[cncontact jobTitle] UTF8String]));

  if ([cncontact isKeyAvailable:CNContactDepartmentNameKey])
    contact.Set("departmentName",
                std::string([[cncontact departmentName] UTF8String]));

  if ([cncontact isKeyAvailable:CNContactOrganizationNameKey])
    contact.Set("organizationName",
                std::string([[cncontact organizationName] UTF8String]));

  if ([cncontact isKeyAvailable:CNContactNoteKey])
    contact.Set("note", std::string([[cncontact note] UTF8String]));

  if ([cncontact isKeyAvailable:CNContactMiddleNameKey])
    contact.Set("middleName", std::string([[cncontact middleName] UTF8String]));

  if ([cncontact isKeyAvailable:CNContactInstantMessageAddressesKey])
    contact.Set("instantMessageAddresses",
                GetInstantMessageAddresses(env, cncontact));

  if ([cncontact isKeyAvailable:CNContactSocialProfilesKey])
    contact.Set("socialProfiles", GetSocialProfiles(env, cncontact));

  return contact;
}

// Parses an array of phone number strings and converts them to an NSArray of
// CNPhoneNumbers.
NSArray *ParsePhoneNumbers(Napi::Array phone_number_data) {
  NSMutableArray *phone_numbers = [[NSMutableArray alloc] init];

  int data_length = static_cast<int>(phone_number_data.Length());
  for (int i = 0; i < data_length; i++) {
    std::string number_str =
        phone_number_data.Get(i).As<Napi::String>().Utf8Value();
    NSString *number = [NSString stringWithUTF8String:number_str.c_str()];
    CNPhoneNumber *phone_number =
        [CNPhoneNumber phoneNumberWithStringValue:number];
    CNLabeledValue *labeled_value =
        [CNLabeledValue labeledValueWithLabel:@"Home" value:phone_number];
    [phone_numbers addObject:labeled_value];
  }

  return phone_numbers;
}

// Parses an array of email address strings and converts them to an NSArray of
// NSStrings.
NSArray *ParseEmailAddresses(Napi::Array email_address_data) {
  NSMutableArray *email_addresses = [[NSMutableArray alloc] init];

  int data_length = static_cast<int>(email_address_data.Length());
  for (int i = 0; i < data_length; i++) {
    std::string email_str =
        email_address_data.Get(i).As<Napi::String>().Utf8Value();
    NSString *email = [NSString stringWithUTF8String:email_str.c_str()];
    CNLabeledValue *labeled_value =
        [CNLabeledValue labeledValueWithLabel:@"Home" value:email];
    [email_addresses addObject:labeled_value];
  }

  return email_addresses;
}

// Parses a string in YYYY-MM-DD format and converts it to an NSDatComponents
// object.
NSDateComponents *ParseBirthday(std::string birth_day) {
  NSString *bday = [NSString stringWithUTF8String:birth_day.c_str()];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd"];

  NSDate *bday_date = [formatter dateFromString:bday];

  NSCalendar *cal = [NSCalendar currentCalendar];
  unsigned unitFlags =
      NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *birthday_components = [cal components:unitFlags
                                                 fromDate:bday_date];

  return birthday_components;
}

// Returns a status indicating whether or not the user has authorized Contacts
// access.
CNAuthorizationStatus AuthStatus() {
  CNEntityType entityType = CNEntityTypeContacts;
  return [CNContactStore authorizationStatusForEntityType:entityType];
}

// Returns the set of Contacts properties to retrieve from the CNContactStore.
NSArray *GetContactKeys(Napi::Array requested_keys) {
  NSMutableArray *keys = [NSMutableArray arrayWithArray:@[
    CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey,
    CNContactEmailAddressesKey, CNContactNicknameKey,
    CNContactPostalAddressesKey, CNContactBirthdayKey
  ]];

  // Iterate through requested keys and add each to the default set.
  int num_keys = requested_keys.Length();
  if (num_keys > 0) {
    for (int i = 0; i < num_keys; i++) {
      Napi::Value val = requested_keys[i];
      std::string key = val.As<Napi::String>().Utf8Value();

      if (key == "contactImage") {
        [keys addObject:CNContactImageDataKey];
      } else if (key == "contactThumbnailImage") {
        [keys addObject:CNContactThumbnailImageDataKey];
      } else if (key == "jobTitle") {
        [keys addObject:CNContactJobTitleKey];
      } else if (key == "departmentName") {
        [keys addObject:CNContactDepartmentNameKey];
      } else if (key == "organizationName") {
        [keys addObject:CNContactOrganizationNameKey];
      } else if (key == "note") {
        [keys addObject:CNContactNoteKey];
      } else if (key == "middleName") {
        [keys addObject:CNContactMiddleNameKey];
      } else if (key == "instantMessageAddresses") {
        [keys addObjectsFromArray:@[
          CNContactInstantMessageAddressesKey,
          CNInstantMessageAddressServiceKey, CNInstantMessageAddressUsernameKey
        ]];
      } else if (key == "socialProfiles") {
        [keys addObjectsFromArray:@[
          CNContactSocialProfilesKey, CNSocialProfileServiceKey,
          CNSocialProfileURLStringKey, CNSocialProfileUsernameKey,
          CNSocialProfileUserIdentifierKey
        ]];
      }
    }
  }

  return keys;
}

// Returns all contacts in the CNContactStore matching a specified name string
// predicate.
NSArray *FindContacts(const std::string &name_string, Napi::Array extra_keys) {
  CNContactStore *addressBook = [[CNContactStore alloc] init];

  NSString *name = [NSString stringWithUTF8String:name_string.c_str()];
  NSPredicate *predicate = [CNContact predicateForContactsMatchingName:name];

  return
      [addressBook unifiedContactsMatchingPredicate:predicate
                                        keysToFetch:GetContactKeys(extra_keys)
                                              error:nil];
}

// Creates a new CNContact in order to update, delete, or add it to the
// CNContactStore.
CNMutableContact *CreateCNMutableContact(Napi::Object contact_data) {
  CNMutableContact *contact = [[CNMutableContact alloc] init];

  if (contact_data.Has("firstName")) {
    std::string first_name =
        contact_data.Get("firstName").As<Napi::String>().Utf8Value();
    [contact setGivenName:[NSString stringWithUTF8String:first_name.c_str()]];
  }

  if (contact_data.Has("lastName")) {
    std::string last_name =
        contact_data.Get("lastName").As<Napi::String>().Utf8Value();
    [contact setFamilyName:[NSString stringWithUTF8String:last_name.c_str()]];
  }

  if (contact_data.Has("nickname")) {
    std::string nick_name =
        contact_data.Get("nickname").As<Napi::String>().Utf8Value();
    [contact setNickname:[NSString stringWithUTF8String:nick_name.c_str()]];
  }

  if (contact_data.Has("birthday")) {
    std::string birth_day =
        contact_data.Get("birthday").As<Napi::String>().Utf8Value();
    NSDateComponents *birthday_components = ParseBirthday(birth_day);
    [contact setBirthday:birthday_components];
  }

  if (contact_data.Has("phoneNumbers")) {
    Napi::Array phone_number_data =
        contact_data.Get("phoneNumbers").As<Napi::Array>();
    NSArray *phone_numbers = ParsePhoneNumbers(phone_number_data);
    [contact setPhoneNumbers:[NSArray arrayWithArray:phone_numbers]];
  }

  if (contact_data.Has("emailAddresses")) {
    Napi::Array email_address_data =
        contact_data.Get("emailAddresses").As<Napi::Array>();
    NSArray *email_addresses = ParseEmailAddresses(email_address_data);
    [contact setEmailAddresses:[NSArray arrayWithArray:email_addresses]];
  }

  return contact;
}

/***** EXPORTED FUNCTIONS *****/

// Returns the user's Contacts access consent status as a string.
Napi::Value GetAuthStatus(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  std::string auth_status = "Not Determined";

  CNAuthorizationStatus status_for_entity = AuthStatus();

  if (status_for_entity == CNAuthorizationStatusAuthorized)
    auth_status = "Authorized";
  else if (status_for_entity == CNAuthorizationStatusDenied)
    auth_status = "Denied";
  else if (status_for_entity == CNAuthorizationStatusRestricted)
    auth_status = "Restricted";

  return Napi::Value::From(env, auth_status);
}

// Returns an array of all a user's Contacts as objects.
Napi::Array GetAllContacts(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  Napi::Array contacts = Napi::Array::New(env);
  CNContactStore *addressBook = [[CNContactStore alloc] init];
  NSMutableArray *cncontacts = [[NSMutableArray alloc] init];
  Napi::Array extra_keys = info[0].As<Napi::Array>();

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return contacts;

  NSArray *containers = [addressBook containersMatchingPredicate:nil error:nil];

  int num_containers = [containers count];
  for (int idx = 0; idx < num_containers; idx++) {
    CNContainer *container = [containers objectAtIndex:idx];
    NSPredicate *predicate = [CNContact
        predicateForContactsInContainerWithIdentifier:[container identifier]];
    NSArray *container_contacts =
        [addressBook unifiedContactsMatchingPredicate:predicate
                                          keysToFetch:GetContactKeys(extra_keys)
                                                error:nil];

    [cncontacts addObjectsFromArray:container_contacts];
  }

  int num_contacts = [cncontacts count];
  for (int i = 0; i < num_contacts; i++) {
    CNContact *cncontact = [cncontacts objectAtIndex:i];
    contacts[i] = CreateContact(env, cncontact);
  }

  return contacts;
}

// Returns an array of all Contacts as objects matching a specified string name.
Napi::Array GetContactsByName(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Array contacts = Napi::Array::New(env);

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return contacts;

  const std::string name_string = info[0].As<Napi::String>().Utf8Value();
  Napi::Array extra_keys = info[1].As<Napi::Array>();
  NSArray *cncontacts = FindContacts(name_string, extra_keys);

  int num_contacts = [cncontacts count];
  for (int i = 0; i < num_contacts; i++) {
    CNContact *cncontact = [cncontacts objectAtIndex:i];
    contacts[i] = CreateContact(env, cncontact);
  }

  return contacts;
}

// Creates and adds a new CNContact to the CNContactStore.
Napi::Boolean AddNewContact(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  CNContactStore *addressBook = [[CNContactStore alloc] init];

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Boolean::New(env, false);

  Napi::Object contact_data = info[0].As<Napi::Object>();
  CNMutableContact *contact = CreateCNMutableContact(contact_data);

  CNSaveRequest *request = [[CNSaveRequest alloc] init];
  [request addContact:contact toContainerWithIdentifier:nil];
  bool success = [addressBook executeSaveRequest:request error:nil];

  return Napi::Boolean::New(env, success);
}

// Removes a CNContact from the CNContactStore.
Napi::Boolean DeleteContact(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Boolean::New(env, false);

  const std::string name_string = info[0].As<Napi::String>().Utf8Value();
  NSArray *cncontacts = FindContacts(name_string, Napi::Array::New(env));

  CNContact *contact = (CNContact *)[cncontacts objectAtIndex:0];
  CNSaveRequest *request = [[CNSaveRequest alloc] init];
  [request deleteContact:[contact mutableCopy]];

  CNContactStore *addressBook = [[CNContactStore alloc] init];
  bool success = [addressBook executeSaveRequest:request error:nil];

  return Napi::Boolean::New(env, success);
}

// Updates an existing CNContact in the CNContactStore.
Napi::Boolean UpdateContact(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Boolean::New(env, false);

  Napi::Object contact_data = info[0].As<Napi::Object>();

  CNMutableContact *contact = CreateCNMutableContact(contact_data);
  CNSaveRequest *request = [[CNSaveRequest alloc] init];
  [request updateContact:contact];

  CNContactStore *addressBook = [[CNContactStore alloc] init];
  bool success = [addressBook executeSaveRequest:request error:nil];

  return Napi::Boolean::New(env, success);
}

// Sets up event listening for changes to the CNContactStore.
Napi::Boolean SetupListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (observer) {
    Napi::Error::New(env, "An observer is already observing")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  ts_fn = Napi::ThreadSafeFunction::New(env, info[0].As<Napi::Function>(),
                                        "emitCallback", 0, 1);

  observer = [[NSNotificationCenter defaultCenter]
      addObserverForName:CNContactStoreDidChangeNotification
                  object:nil
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(NSNotification *note) {
                auto callback = [](Napi::Env env, Napi::Function js_cb,
                                   const char *value) {
                  js_cb.Call({Napi::String::New(env, value)});
                };
                ts_fn.BlockingCall("contact-changed", callback);
              }];

  return Napi::Boolean::New(env, true);
}

// Removes event listening for changes to the CNContactStore.
Napi::Boolean RemoveListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (!observer) {
    Napi::Error::New(env, "No observers are currently observing")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  // Release thread-safe function.
  ts_fn.Release();

  // Remove observer from the Notification Center.
  [[NSNotificationCenter defaultCenter] removeObserver:observer];

  // Reset observer.
  observer = nullptr;

  return Napi::Boolean::New(env, true);
}

// Indicates whether event listening for changes to the CNContactStore is in
// place.
Napi::Boolean IsListening(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  bool is_listening = observer != nullptr;

  return Napi::Boolean::New(env, is_listening);
}

// Initializes all functions exposed to JS.
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "setupListener"),
              Napi::Function::New(env, SetupListener));
  exports.Set(Napi::String::New(env, "removeListener"),
              Napi::Function::New(env, RemoveListener));
  exports.Set(Napi::String::New(env, "isListening"),
              Napi::Function::New(env, IsListening));
  exports.Set(Napi::String::New(env, "getAuthStatus"),
              Napi::Function::New(env, GetAuthStatus));
  exports.Set(Napi::String::New(env, "getAllContacts"),
              Napi::Function::New(env, GetAllContacts));
  exports.Set(Napi::String::New(env, "getContactsByName"),
              Napi::Function::New(env, GetContactsByName));
  exports.Set(Napi::String::New(env, "addNewContact"),
              Napi::Function::New(env, AddNewContact));
  exports.Set(Napi::String::New(env, "deleteContact"),
              Napi::Function::New(env, DeleteContact));
  exports.Set(Napi::String::New(env, "updateContact"),
              Napi::Function::New(env, UpdateContact));

  return exports;
}

NODE_API_MODULE(contacts, Init)