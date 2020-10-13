//
//  ViewController.m
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import "ViewController.h"
#import "LinkSymbol.h"
#import "OutlineNode.h"
#import "MsgMerger.h"


@interface ViewController()<NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSTextField *textField;
@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSTextField *searchField;
@property (weak) IBOutlet NSButton *isAaState;

@property (strong) NSArray<OutlineNode<LinkSymbol *> *> *nodes;
@property (strong) NSArray<OutlineNode<LinkSymbol *> *> *displayNodes;

@property (strong) MsgMerger *msgMerger;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicator.hidden = YES;
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    self.searchField.delegate = self;
    self.msgMerger = [MsgMerger msgMergerWithTarget:self sel:@selector(reloadSearchData)];
}

- (IBAction)isAaStateAction:(NSButton *)sender {
    [self reloadSearchData];
}

- (IBAction)openFileAction:(NSButton *)sender {
    [self openFilePanel:YES callback:^(NSString *path) {
        self.indicator.hidden = NO;
        sender.enabled = NO;
        [self.indicator startAnimation:self];
        [self analyzeLinkMapFile:path callback:^(NSArray<OutlineNode<LinkSymbol *> *> *nodes) {
            self.indicator.hidden = YES;
            [self.indicator stopAnimation:self];
            self.textField.stringValue = path;
            self.nodes = nodes;
            [self reloadSearchData];
            if (nodes.count == 0) {
                [self showAlertWithTitle:@"请检查输入文件" messate:path];
            }
            sender.enabled = YES;
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
        return self.displayNodes;
    }
    else {
        return ((OutlineNode *)node).childNodes;
    }
}

- (void)reloadSearchData {
    
    NSString *keywork = self.searchField.stringValue;
    if (keywork.length > 0) {
        BOOL isAa = self.isAaState.state == NSControlStateValueOn;
        self.displayNodes = [OutlineNode<LinkSymbol *> filterNodes:self.nodes condition:^BOOL(LinkSymbol * _Nonnull content) {
            return [content.name rangeOfString:keywork options:isAa ? NSLiteralSearch : NSCaseInsensitiveSearch].length > 0;
        }];
    }else {
        self.displayNodes = self.nodes;
    }
    
    [self.outlineView reloadData];
    
    if (keywork.length > 0) {
        for (OutlineNode *node in self.displayNodes) {
            if (node.childNodes.count > 0) {
                [self.outlineView expandItem:node];
            }
        }
    }
}

- (NSAttributedString *)keyworkString:(NSString *)string keywork:(NSString *)keywork isAa:(BOOL)isAa {
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];
    NSRange range = [string rangeOfString:keywork options:isAa ? NSLiteralSearch : NSCaseInsensitiveSearch];
    if (range.length > 0) {
        [str addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:range];
    }
    return [str copy];
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

    NSString *identifier;
    if (column == 0) {
        identifier = @"cellView0";
    }
    else{
        identifier = @"cellView1";
    }
    
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
    
    LinkSymbol *symbol = ((OutlineNode *)item).content;
    if (column == 0) {
        cellView.textField.stringValue = symbol.sizeString;
    }else {
        cellView.textField.attributedStringValue = [self keyworkString:symbol.name keywork:self.searchField.stringValue isAa:NO];
    }

    return cellView;
}

//- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
//    return 30.0f;
//}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
    if (self.nodes.count > 0) {
        [self.msgMerger performMsg];
    }
}

@end
