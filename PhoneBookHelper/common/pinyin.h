/*
 *  pinyin.h
 *  Chinese Pinyin First Letter
 *
 *  Created by George on 4/21/10.
 *  Copyright 2010 RED/SAFI. All rights reserved.
 *
 */

/*
 * // Example
 *
 * #import "pinyin.h"
 *
 * NSString *hanyu = @"中国";
 * for (int i = 0; i < [hanyu length]; i++)
 * {
 *     printf("%c", pinyinFirstLetter([hanyu characterAtIndex:i]));
 * }
 *
 */
#define ALPHA	@"ABCDEFGHIJKLMNOPQRSTUVWXYZ#"


#ifdef __cplusplus
extern "C"
{
#endif

char pinyinFirstLetter(unsigned short hanzi);
signed char isHanzi(unsigned short ch);

#ifdef __cplusplus
}
#endif
