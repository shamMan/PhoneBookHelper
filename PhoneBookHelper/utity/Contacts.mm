//
//  Contacts.m
//  PhoneBookHelper
//
//  Created by ShawLiao on 13-5-13.
//  Copyright (c) 2013年 ShawLiao. All rights reserved.
//

#import "Contacts.h"
#import <AddressBook/AddressBook.h>
#import "pinyin.h"

#define kFlagMobileLabel        @"_$!<Mobile>!$_"
#define kAddressBookChangedNotificationName     @"ContactsList.AddressBookChangedNotification"

@interface ContactsItem ()
@property  (assign, nonatomic) ABRecordRef recordref;
@end

@implementation ContactsItem

#pragma mark - Getter & Setter
- (void)setDisplayName:(NSString *)displayName
{
    if (displayName!=_displayName)
    {
        [_displayName release];
        _displayName    =   [displayName retain];
        
        // 字母化的名字
        if ([_displayName length]>0)
        {
            NSMutableString* alphabeticName = [NSMutableString string];
            for (NSUInteger i = 0; i < [_displayName length]; ++i) {
                char alpha = pinyinFirstLetter([_displayName characterAtIndex:i]);
                [alphabeticName appendFormat:@"%c", alpha];
            }
            self.pinyinName = [alphabeticName uppercaseString];
        }
    }
}

-(id) init
{
    // 防止调用默认的此方法
    throw([NSException exceptionWithName:@"Exception throw by Shaw" reason:@"ContactsItem init method is forbiden!" userInfo:nil]);
}

-(void) dealloc
{
    [_displayName release];
    [_pinyinName release];
    [_phoneLabels release];
    [_phoneNumbers release];
    [_mobileNumber release];
    [_icon release];
    return [super dealloc];
}

#pragma mark - Private
+ (NSString*)formatToNumberizedString:(NSString*)string
{
    NSMutableString* retString = [NSMutableString string];
    for (NSUInteger i = 0; i < [string length]; ++i) {
        unichar ch = [string characterAtIndex:i];
        if ((ch >= '0' && ch <= '9') || ch == '+') {
            [retString appendFormat:@"%C", ch];
        }
    }
    return retString;
}

#pragma mark Getting MultiValue Elements
- (NSArray *) arrayForProperty: (ABPropertyID) anID
{
	CFTypeRef theProperty = ABRecordCopyValue(self.recordref, anID);
	NSArray *items = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(theProperty);
	CFRelease(theProperty);
	return [items autorelease];
}

- (NSArray *) labelsForProperty: (ABPropertyID) anID isLocalized:(BOOL)isLocalized
{
	CFTypeRef theProperty = ABRecordCopyValue(self.recordref, anID);
	NSMutableArray* labels = nil;
	for (int i = 0; i < ABMultiValueGetCount(theProperty); i++)
	{
		CFStringRef label = ABMultiValueCopyLabelAtIndex(theProperty, i);
        NSString* resultLabel = nil;
        if (isLocalized) {
            resultLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(label);
            CFRelease(label);
        } else {
            resultLabel = (__bridge NSString*)label;
        }
        if (resultLabel) {
            if (labels == nil) {
                labels = [NSMutableArray array];
            }
            [labels addObject:resultLabel];
            [resultLabel release];
        }
	}
	CFRelease(theProperty);
	return labels;
}

- (BOOL)isValuable
{
    if (self.displayName == nil) {
        return NO;
    }
    if (self.phoneLabels == nil || self.phoneNumbers == nil) {
        return NO;
    }
    if (self.phoneLabels.count == 0 || self.phoneNumbers.count == 0) {
        return NO;
    }
    return YES;
}

- (id)initWithRecordRef:(ABRecordRef) recordref
{
    self = [super init];
    if (self)
    {
        self.recordref  =   recordref;
        // 显示名字
        CFStringRef displayNameRef = ABRecordCopyCompositeName(recordref); // may be nil
        self.displayName = (__bridge NSString*)displayNameRef;
        if (displayNameRef) {
            CFRelease(displayNameRef);
        }
        else
        {
            NSLog(@"displayName == nil");
        }
        // 电话号码
        self.phoneNumbers = [self arrayForProperty:kABPersonPhoneProperty];
        self.phoneLabels = [self labelsForProperty:kABPersonPhoneProperty isLocalized:NO];
        
        [_mobileNumber release];
        _mobileNumber   =   nil;
        NSAssert([self.phoneLabels count] == [self.phoneNumbers count], nil);
        for (NSUInteger i = 0; i < [self.phoneLabels count]; ++i) {
            if ([[self.phoneLabels objectAtIndex:i] isEqualToString:kFlagMobileLabel]) {
                _mobileNumber   =   [[self.phoneNumbers objectAtIndex:i] retain];
            }
        }
        
        if (self.isValuable) {
            // 头像
            if (ABPersonHasImageData(self.recordref)) {
                CFDataRef imageData = ABPersonCopyImageDataWithFormat(self.recordref,kABPersonImageFormatThumbnail);
                self.icon   = [UIImage imageWithData:(__bridge NSData *) imageData];
                CFRelease(imageData);
            }
        }
    }
    return self;
}

- (NSString *)description
{
    NSString* ret   =   [NSString stringWithFormat:@"[ name:%@ pinyin:%@ lables:%@ numbers:%@ ]",self.displayName,self.pinyinName,self.phoneLabels,self.phoneNumbers];
    return ret;
}

@end

//------------------------------------------------------------
// ContactsList implement
//------------------------------------------------------------

@interface ContactsList ()
@property (assign, nonatomic) ABAddressBookRef addressBookRef;
@end

@implementation ContactsList

#pragma mark - ABAddressBookExternalChangeCallback fun
void addressBookExternalChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context)
{
    [(ContactsList*)context UpdateContractList];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddressBookChangedNotificationName
                                                        object:(id)context];
}

static ContactsList* g_sharedContactsList = nil;
static dispatch_once_t gs_sharedContactsList_onceTakon = nil;

-(void) dealloc
{
    if (_addressBookRef) {
        CFRelease(_addressBookRef);
        _addressBookRef =   0;
    }
    [_recordList release];
    return [super dealloc];
}

- (id)init
{
    self    =   [super init];
    if (self)
    {
        ABAddressBookRef    addressBookRef    =   nil;
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0f)
        {
            // ask permisstion
            CFErrorRef error;
            addressBookRef  =   ABAddressBookCreateWithOptions(NULL, &error);
            if (error)
            {
                NSError* nserror    =   (NSError*)error;
                NSLog(@"ABAddressBookCreateWithOptions failed!:%@",nserror);
            }
            else
            {
                
            }
            dispatch_semaphore_t sema   =   dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error)
                                                     {
                                                         dispatch_semaphore_signal(sema);
                                                         if (granted) {
                                                             NSLog(@"access address book success");
                                                         }
                                                         else
                                                         {
                                                             NSLog(@"access address book failed!");
                                                         }
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_release(sema);
        }
        else
        {
            // just get
            addressBookRef =    ABAddressBookCreate();
        }
        self.addressBookRef =   addressBookRef;
        // 注册联系人改变回调
        ABAddressBookRegisterExternalChangeCallback(self.addressBookRef, addressBookExternalChangeCallback, self);
        [self UpdateContractList];
    }
    return self;
}

- (BOOL)UpdateContractList
{
    BOOL ret    =   TRUE;
    // 获取 全部
    //NSArray* records  =   (NSArray*)ABAddressBookCopyArrayOfAllPeople(self.addressBookRef);
    ABRecordRef source  =   ABAddressBookCopyDefaultSource(self.addressBookRef);
    CFIndex numberOfContacts    =   ABAddressBookGetPersonCount(self.addressBookRef);
    NSArray* records    =   (NSArray*)ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(self.addressBookRef, source,kABPersonSortByFirstName);
    CFRelease(source);
    if (_recordList) {
        [_recordList release];
    }
    _recordList =   [[NSMutableArray alloc] init];
    
    for (id object in records) {
        ABRecordRef record  =   (ABRecordRef)object;
        ContactsItem* item  =   [[[ContactsItem alloc] initWithRecordRef:record] autorelease];
        [_recordList addObject:item];
    }
    [records release];
    NSLog(@"Contacts:%@",_recordList);
    return ret;
}

// 获取单例
+ (const ContactsList* const)sharedContactsList
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedContactsList   =   [[ContactsList alloc] init];
    });
    return g_sharedContactsList;
}
// 摧毁单例 (程序退出时自动被调用)
+ (void)destroyContactsList
{
    gs_sharedContactsList_onceTakon = nil;
    [g_sharedContactsList release];
    g_sharedContactsList = nil;
}

class ContractsDestoryer
{
public:
    ContractsDestoryer(){}
    ~ContractsDestoryer(){[ContactsList destroyContactsList];}
};

static ContractsDestoryer contractsDestoryer;

- (void)addObserver:(NSObject*)observer selector:(SEL)aSelector
{
    [[NSNotificationCenter defaultCenter] addObserver:observer
                                             selector:aSelector
                                                 name:kAddressBookChangedNotificationName
                                               object:nil];
}

- (void)removeObserver:(NSObject*)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kAddressBookChangedNotificationName object:self];
}

@end
