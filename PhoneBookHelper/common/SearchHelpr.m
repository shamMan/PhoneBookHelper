//
//  SearchHelpr.m
//  PhoneBookHelper
//
//  Created by ShawLiao on 13-5-16.
//  Copyright (c) 2013年 ShawLiao. All rights reserved.
//

#import "SearchHelpr.h"

@interface SearchHelper()
@property (retain,nonatomic) NSString* searchKeywords;
@property (retain,nonatomic) NSMutableArray* searchResultStack;
@end

@implementation SearchHelper
-(NSArray*) searchResultForKeyword:(NSString*) keyword;
{
    if (self.searchBlock && self.sourceArray)
    {
        // 适用当前的
        if (!self.searchResultStack) {
            self.searchResultStack  =   [[[NSMutableArray alloc] init] autorelease];
            [self.searchResultStack addObject:self.sourceArray];
        }
        // 先判断当前 keyword 和 已存在的keyword差别
        if (self.searchKeywords && [keyword hasPrefix:self.searchKeywords])
        {
            
        }
        else
        {
            while ([self.searchResultStack count]>1)
                [self.searchResultStack removeLastObject];
        }
        NSArray*    newResult   =   self.searchBlock([self.searchResultStack lastObject],keyword);
        [self.searchResultStack addObject:newResult];
        self.searchKeywords =   keyword;
        return  [self.searchResultStack lastObject];
    }
    else
    {
        return nil;
    }
}
@end
