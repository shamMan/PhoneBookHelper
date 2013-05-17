//
//  SearchHelpr.h
//  PhoneBookHelper
//
//  Created by ShawLiao on 13-5-16.
//  Copyright (c) 2013年 ShawLiao. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NSArray* (^SearchBlock) (NSArray* source,NSString* keywords);

@interface SearchHelper : NSObject
@property (assign,nonatomic) SearchBlock   searchBlock;
@property (retain,nonatomic) NSArray*      sourceArray;

// search
-(NSArray*) searchResultForKeyword:(NSString*) keyword;

@end

