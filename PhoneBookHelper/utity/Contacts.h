//
//  Contacts.h
//  PhoneBookHelper
//
//  Created by ShawLiao on 13-5-13.
//  Copyright (c) 2013年 ShawLiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactsItem : NSObject
// 头像
@property (retain ,nonatomic) UIImage*  icon;
// 姓名
@property (retain, nonatomic) NSString* displayName;
// 拼音首字母
@property (retain, nonatomic) NSString* pinyinName;
// 电话号码数组
@property (retain, nonatomic) NSArray* phoneNumbers;
// 电话类别标签数组
@property (retain, nonatomic) NSArray* phoneLabels;
// 手机号码
@property (readonly, nonatomic) NSString* mobileNumber;

@end


//------------------------------------------------------------
// ContactsList 注：此类为单例，因为多个 ABAddressBookRef 容易造成程序 crash
//------------------------------------------------------------

@interface ContactsList : NSObject
// 联系人列表 (数组元素是 ContactItem)
@property (readonly, nonatomic) NSMutableArray* recordList;
// 设备的联系人是否有权访问
@property (assign, nonatomic, getter = isContactsAccessible) BOOL contactsAccessible;

// 获取单例
+ (const ContactsList* const)sharedContactsList;
// 摧毁单例 (程序退出时自动被调用)
+ (void)destroyContactsList;
// 注册联系人改变的观察者 // selector: - (void)addressBookChangedNotifer:(NSNotification*)param
- (void)addObserver:(NSObject*)observer selector:(SEL)aSelector;
// 移除观察者
- (void)removeObserver:(NSObject*)observer;
@end
