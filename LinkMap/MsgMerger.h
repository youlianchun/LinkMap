//
//  MsgMerger.h
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MsgMerger : NSObject
@property (nonatomic, weak, readonly, nullable) id target;
@property (nonatomic, assign, readonly) SEL sel;

+ (instancetype)msgMergerWithTarget:(id)target sel:(SEL)sel;
- (void)performMsg;
- (void)performMsg:(id)obj;
@end

NS_ASSUME_NONNULL_END
