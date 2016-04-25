//
//  NSString+SHA1.h
//  app
//
//  Created by 刘华舟 on 15/5/28.
//  Copyright (c) 2015年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHA1)

/**
 * Creates a SHA1 (hash) representation of NSString.
 *
 * @return NSString
 */
- (NSString *)sha1;

@end
