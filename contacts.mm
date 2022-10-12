#include "node.h"
#import <AppKit/AppKit.h>
#import <Contacts/Contacts.h>
#include <napi.h>

Napi::ThreadSafeFunction ts_fn;
id observer = nil;

Napi::Reference<Napi::Array> contacts_ref;

/***** HELPERS *****/

// Dummy value to pass into function parameter for ThreadSafeFunction.
Napi::Value NoOp(const Napi::CallbackInfo &info) {
  return info.Env().Undefined();
}

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
  NSDate *birth_date = [[cncontact birthday] date];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd"];

  NSString *birthday = [formatter stringFromDate:birth_date];
  return birthday ? std::string([birthday UTF8String]) : "";
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

// Parses and returns an array of URL addresses as strings.
Napi::Array GetUrlAddresses(Napi::Env env, CNContact *cncontact) {
  int num_url_addresses = [[cncontact urlAddresses] count];

  Napi::Array url_addresses = Napi::Array::New(env, num_url_addresses);
  NSArray<CNLabeledValue<NSString *> *> *urlAddresses =
      [cncontact urlAddresses];
  for (int i = 0; i < num_url_addresses; i++) {
    CNLabeledValue<NSString *> *url_address = [urlAddresses objectAtIndex:i];
    url_addresses[i] = std::string([[url_address value] UTF8String]);
  }

  return url_addresses;
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

  if ([cncontact isKeyAvailable:CNContactUrlAddressesKey]) {
    Napi::Array url_addresses = GetUrlAddresses(env, cncontact);
    contact.Set("urlAddresses", url_addresses);
  }

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
        [CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberMobile
                                        value:phone_number];
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
        [CNLabeledValue labeledValueWithLabel:CNLabelHome value:email];
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

// Parses an array of url address strings and converts them to an NSArray of
// NSStrings.
NSArray *ParseUrlAddresses(Napi::Array url_address_data) {
  NSMutableArray *url_addresses = [[NSMutableArray alloc] init];

  int data_length = static_cast<int>(url_address_data.Length());
  for (int i = 0; i < data_length; i++) {
    std::string url_str =
        url_address_data.Get(i).As<Napi::String>().Utf8Value();
    NSString *url = [NSString stringWithUTF8String:url_str.c_str()];
    CNLabeledValue *labeled_value =
        [CNLabeledValue labeledValueWithLabel:CNLabelHome value:url];
    [url_addresses addObject:labeled_value];
  }

  return url_addresses;
}

// Returns a status indicating whether or not the user has authorized Contacts
// access.
CNAuthorizationStatus AuthStatus() {
  CNEntityType entityType = CNEntityTypeContacts;
  return [CNContactStore authorizationStatusForEntityType:entityType];
}

// Returns the authorization status as a string.
std::string AuthStatusString() {
  switch (AuthStatus()) {
  case CNAuthorizationStatusAuthorized:
    return "Authorized";
  case CNAuthorizationStatusDenied:
    return "Denied";
  case CNAuthorizationStatusRestricted:
    return "Restricted";
  default:
    return "Not Determined";
  }
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
      } else if (key == "urlAddresses") {
        [keys addObject:CNContactUrlAddressesKey];
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

// Returns all contacts in the CNContactStore matching an identifier
NSArray *FindContactsWithIdentifier(const std::string &identifier_string,
                                    Napi::Array extra_keys) {
  CNContactStore *addressBook = [[CNContactStore alloc] init];

  NSString *identifier =
      [NSString stringWithUTF8String:identifier_string.c_str()];

  NSArray *identifiers = @[ identifier ];

  NSPredicate *predicate =
      [CNContact predicateForContactsWithIdentifiers:identifiers];

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

  if (contact_data.Has("middleName")) {
    std::string middle_name =
        contact_data.Get("middleName").As<Napi::String>().Utf8Value();
    [contact setMiddleName:[NSString stringWithUTF8String:middle_name.c_str()]];
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

  if (contact_data.Has("jobTitle")) {
    std::string job_title =
        contact_data.Get("jobTitle").As<Napi::String>().Utf8Value();
    [contact setJobTitle:[NSString stringWithUTF8String:job_title.c_str()]];
  }

  if (contact_data.Has("departmentName")) {
    std::string department_name =
        contact_data.Get("departmentName").As<Napi::String>().Utf8Value();
    [contact
        setDepartmentName:[NSString
                              stringWithUTF8String:department_name.c_str()]];
  }

  if (contact_data.Has("organizationName")) {
    std::string organization_name =
        contact_data.Get("organizationName").As<Napi::String>().Utf8Value();
    [contact
        setOrganizationName:[NSString stringWithUTF8String:organization_name
                                                               .c_str()]];
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

  if (contact_data.Has("urlAddresses")) {
    Napi::Array url_address_data =
        contact_data.Get("urlAddresses").As<Napi::Array>();
    NSArray *url_addresses = ParseUrlAddresses(url_address_data);
    [contact setUrlAddresses:[NSArray arrayWithArray:url_addresses]];
  }

  return contact;
}

/***** EXPORTED FUNCTIONS *****/

// Request Contacts access.
Napi::Promise RequestAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "contactsCallback", 0, 1);

  if (@available(macOS 10.11, *)) {
    std::string status = AuthStatusString();

    if (status == "Not Determined") {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      CNContactStore *store = [CNContactStore new];
      [store requestAccessForEntityType:CNEntityTypeContacts
                      completionHandler:^(BOOL granted, NSError *error) {
                        auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                            const char *granted) {
                          deferred.Resolve(Napi::String::New(env, granted));
                        };
                        tsfn.BlockingCall(granted ? "Authorized" : "Denied",
                                          callback);
                        tsfn.Release();
                      }];
    } else if (status == "Denied") {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Contacts";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "Denied"));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "Authorized"));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "Authorized"));
  }

  return deferred.Promise();
}

// Returns the user's Contacts access consent status as a string.
Napi::Value GetAuthStatus(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  return Napi::Value::From(env, AuthStatusString());
}

// Returns an array of all a user's Contacts as objects.
Napi::Array GetAllContacts(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Array::New(env);

  if (!contacts_ref.IsEmpty())
    return contacts_ref.Value();

  CNContactStore *addressBook = [[CNContactStore alloc] init];
  Napi::Array extra_keys = info[0].As<Napi::Array>();

  NSError *error = nil;
  NSArray *containers = [addressBook containersMatchingPredicate:nil
                                                           error:&error];
  if (error != nil) {
    std::string err_msg = std::string([error.localizedDescription UTF8String]);
    Napi::Error::New(env, "Failed to fetch address book container: " + err_msg)
        .ThrowAsJavaScriptException();
    return Napi::Array::New(env);
  }

  // This is a set so that contacts in multiple containers aren't duplicated.
  NSMutableSet *unordered_contacts = [[NSMutableSet alloc] init];
  int num_containers = [containers count];
  for (int idx = 0; idx < num_containers; idx++) {
    CNContainer *container = [containers objectAtIndex:idx];
    NSPredicate *predicate = [CNContact
        predicateForContactsInContainerWithIdentifier:[container identifier]];
    NSArray *container_contacts =
        [addressBook unifiedContactsMatchingPredicate:predicate
                                          keysToFetch:GetContactKeys(extra_keys)
                                                error:&error];
    if (error != nil) {
      std::string err_msg =
          std::string([error.localizedDescription UTF8String]);
      Napi::Error::New(env, "Failed to fetch contacts: " + err_msg)
          .ThrowAsJavaScriptException();
      return Napi::Array::New(env);
    }

    [unordered_contacts addObjectsFromArray:container_contacts];
  }

  Napi::Array contacts = Napi::Array::New(env);
  NSArray *cncontacts = [unordered_contacts allObjects];
  int num_contacts = [cncontacts count];
  for (int i = 0; i < num_contacts; i++) {
    CNContact *cncontact = [cncontacts objectAtIndex:i];
    contacts[i] = CreateContact(env, cncontact);
  }

  contacts_ref = Napi::Persistent(contacts);

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
  CNContactStore *address_book = [[CNContactStore alloc] init];

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Boolean::New(env, false);

  Napi::Object contact_data = info[0].As<Napi::Object>();
  CNMutableContact *contact = CreateCNMutableContact(contact_data);

  CNSaveRequest *request = [[CNSaveRequest alloc] init];

  // Apple docs say you can add a contact by calling
  // addContact:toContainerWithIdentifier: and setting identifier to nil
  // but this is current causing a crash on macOS Ventura so we
  // fetch the default container id explicitly to work around this.
  NSString *container_id = [address_book defaultContainerIdentifier];
  [request addContact:contact toContainerWithIdentifier:container_id];
  bool success = [address_book executeSaveRequest:request error:nil];

  return Napi::Boolean::New(env, success);
}

// Removes a CNContact from the CNContactStore.
Napi::Boolean DeleteContact(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (AuthStatus() != CNAuthorizationStatusAuthorized)
    return Napi::Boolean::New(env, false);

  Napi::Object contact_data = info[0].As<Napi::Object>();

  NSArray *cncontacts;
  if (contact_data.Has("identifier")) {
    const std::string identifier =
        contact_data.Get("identifier").As<Napi::String>().Utf8Value();
    cncontacts = FindContactsWithIdentifier(identifier, Napi::Array::New(env));
  } else if (contact_data.Has("name")) {
    const std::string name_string =
        contact_data.Get("name").As<Napi::String>().Utf8Value();
    cncontacts = FindContacts(name_string, Napi::Array::New(env));
  } else {
    return Napi::Boolean::New(env, false);
  }

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

  if (observer != nil) {
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
              usingBlock:^(NSNotification *notification) {
                NSDictionary *info = [notification userInfo];
                if ([info count] == 0)
                  return;

                contacts_ref.Reset();
                bool external =
                    [[info objectForKey:@"CNNotificationOriginationExternally"]
                        boolValue];

                auto callback = [external](Napi::Env env, Napi::Function js_cb,
                                           const char *value) {
                  js_cb.Call({Napi::String::New(env, value),
                              Napi::Boolean::New(env, external)});
                };

                ts_fn.BlockingCall("contact-changed", callback);
              }];

  return Napi::Boolean::New(env, true);
}

// Removes event listening for changes to the CNContactStore.
Napi::Boolean RemoveListener(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (observer == nil) {
    Napi::Error::New(env, "No observers are currently observing")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::New(env, false);
  }

  // Release thread-safe function.
  ts_fn.Release();

  // Remove observer from the Notification Center.
  [[NSNotificationCenter defaultCenter] removeObserver:observer];

  // Reset observer to nil.
  observer = nil;

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
  exports.Set(Napi::String::New(env, "requestAccess"),
              Napi::Function::New(env, RequestAccess));
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

  auto *isolate = v8::Isolate::GetCurrent();
  node::AddEnvironmentCleanupHook(
      isolate, [](void *) { contacts_ref.Reset(); }, isolate);

  return exports;
}

NODE_API_MODULE(contacts, Init)
