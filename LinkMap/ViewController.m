//
//  ViewController.m
//  LinkMap
//
//  Created by ylchun on 4/8/15.
//  Copyright © 2015 YLCHUM. All rights reserved.
//

#import "ViewController.h"
#import "LinkSymbol.h"
#import "OutlineNode.h"

@interface ViewController()<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSTextField *textField;
@property (weak) IBOutlet NSProgressIndicator *indicator;

@property (strong) NSArray<OutlineNode<LinkSymbol *> *> *nodes;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicator.hidden = YES;
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
}

- (IBAction)openFileAction:(id)sender {
    [self openFilePanel:YES callback:^(NSString *path) {
        self.indicator.hidden = NO;
        [self.indicator startAnimation:self];
        [self analyzeLinkMapFile:path callback:^(NSArray<OutlineNode<LinkSymbol *> *> *nodes) {
            self.indicator.hidden = YES;
            [self.indicator stopAnimation:self];
            self.textField.stringValue = path;
            self.nodes = nodes;
            [self.outlineView reloadData];
            if (nodes.count == 0) {
                [self showAlertWithTitle:@"请检查输入文件" messate:path];
            }
        }];
    }];
}

- (void)openFilePanel:(BOOL)isFile callback:(void(^)(NSString *path))callback {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = isFile;

    [panel beginWithCompletionHandler:^(NSModalResponse result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *path = panel.URLs.firstObject;
            callback(path.path);
        }
    }];
}

- (void)analyzeLinkMapFile:(NSString *)file callback:(void(^)(NSArray<OutlineNode<LinkSymbol *> *> *nodes))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<LinkSymbol *> *symbols = [LinkSymbol symbolsOfLinkMapFile:file combination:YES keyword:nil];
        NSArray *nodes = [self nodesFromSymbols:symbols];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback([nodes copy]);
        });
    });
}

- (NSArray<OutlineNode *> *)nodesFromSymbols:(NSArray<LinkSymbol *> *)symbols {
    if (symbols.count == 0) {
        return nil;
    }
    NSMutableArray *nodes = [NSMutableArray array];
    for (LinkSymbol *symbol in symbols) {
        OutlineNode *node = [OutlineNode new];
        node.content = symbol;
        node.childNodes = [self nodesFromSymbols:symbol.childs];
        [nodes addObject:node];
    }
    return [nodes copy];
}


- (void)showAlertWithTitle:(NSString *)title messate:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = title;
    if (message) {
        alert.informativeText = message;
    }
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (NSArray<OutlineNode *> *)childNodes:(OutlineNode *)node {
    if (node == nil) {
        return self.nodes;
    }
    else {
        return ((OutlineNode *)node).childNodes;
    }
}

#pragma mark - NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [self childNodes:item].count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [self childNodes:item].count > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self childNodes:item][index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

#pragma mark - NSOutlineViewDelegate
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSUInteger column = [outlineView.tableColumns indexOfObject:tableColumn];

    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"cellView" owner:self];
    
    LinkSymbol *symbol = ((OutlineNode *)item).content;
    if (column == 0) {
        cellView.textField.stringValue = symbol.sizeString;
    }
    else{
        cellView.textField.stringValue = symbol.name;
    }
    return cellView;
}

//- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
//    return 30.0f;
//}

@end
