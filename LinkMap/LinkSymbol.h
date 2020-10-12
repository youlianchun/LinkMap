//
//  LinkSymbol.h
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import <Foundation/Foundation.h>

@interface LinkSymbol : NSObject

@property (nonatomic, readonly) NSString *file;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSString *sizeString;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray<LinkSymbol *> *childs;
@end

@interface LinkSymbol(LinkMap)
+ (NSArray<LinkSymbol *> *)symbolsOfLinkMapFile:(NSString *)file combination:(BOOL)combination keyword:(NSString *)keyword;
@end
