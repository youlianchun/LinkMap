//
//  OutlineNode.h
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OutlineNode<ContentType> : NSObject
@property (nonatomic, strong) ContentType content;
@property (nonatomic, copy) NSArray<OutlineNode *> *childNodes;

+ (NSArray<OutlineNode<ContentType> *> *)filterNodes:(NSArray<OutlineNode<ContentType> *> *)nodes condition:(BOOL(^)(ContentType content))condition;
@end

NS_ASSUME_NONNULL_END
