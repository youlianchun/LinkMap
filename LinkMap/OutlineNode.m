//
//  OutlineNode.m
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import "OutlineNode.h"

@implementation OutlineNode

+ (NSArray<OutlineNode<id> *> *)filterNodes:(NSArray<OutlineNode<id> *> *)nodes condition:(BOOL(^)(id content))condition {
    if (nodes.count == 0 || !condition) {
        return nodes;
    }
    NSMutableArray *arr = [NSMutableArray array];
    for (OutlineNode *node in nodes) {
        NSArray *childNodes = [self filterNodes:node.childNodes condition:condition];
        if (condition(node.content) || childNodes.count > 0) {
            OutlineNode *newNode = [[OutlineNode alloc] init];
            newNode.content = node.content;
            newNode.childNodes = childNodes;
            [arr addObject:newNode];
        }
    }
    return [arr copy];
}
@end
