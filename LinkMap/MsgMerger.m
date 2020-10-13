//
//  MsgMerger.m
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import "MsgMerger.h"

@implementation MsgMerger
{
    dispatch_source_t _source;
    dispatch_queue_t _queue;
    id _param;
    NSLock *_lock;
}
@synthesize target = _target, sel = _sel;

+ (instancetype)msgMergerWithTarget:(id)target sel:(SEL)sel {
    return [[self alloc] initWithTarget:target sel:sel];
}

- (instancetype)initWithTarget:(id)target sel:(SEL)sel {
    self = [super init];
    if (self) {
        _target = target;
        _sel = sel;
        _lock = [NSLock new];
        _queue = dispatch_queue_create(super.description.UTF8String, DISPATCH_QUEUE_SERIAL);
        _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _queue);
        [self prepare];
    }
    return self;
}

- (void)dealloc {
    if (_source) {
        dispatch_source_cancel(_source);
        _source = nil;
    }
    _queue = nil;
}

- (void)prepare {
    __weak typeof(self) wself = self;
    dispatch_source_set_event_handler(_source, ^{
        [wself onMerge];
        sleep(1);
    });
    dispatch_resume(_source);
}

- (void)performMsg {
    dispatch_source_merge_data(_source, 1);
}

- (void)onMerge {
    if (!_target) {
        return;
    }
    id target = _target;
    SEL sel = _sel;
    [_lock lock];
    id obj = _param;
    _param = nil;
    [_lock unlock];
    if (target != nil && sel != NULL && [target respondsToSelector:sel]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [target performSelector:sel withObject:obj afterDelay:0];
        });
    }
}

- (void)performMsg:(id)obj {
    [_lock lock];
    _param = obj;
    [_lock unlock];
    [self performMsg];
}
@end
