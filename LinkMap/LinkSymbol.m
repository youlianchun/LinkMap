//
//  LinkSymbol.m
//  LinkMap
//
//  Created by YLCHUN on 2020/10/11.
//

#import "LinkSymbol.h"

@implementation LinkSymbol
@synthesize file = _file, size = _size, name = _name, childs = _childs;

- (NSString *)sizeString {
    NSArray *units = @[@"K", @"M", @"G"];
    double size = self.size;
    NSString *unit = nil;
    for (unit in units) {
        size = size / 1024.0;
        if (size < 1024.0) {
            break;
        }
    }
    return [NSString stringWithFormat:@"%.2f %@", size, unit];
}

@end

#pragma mark -
@implementation LinkSymbol(LinkMap)

+ (NSArray<LinkSymbol *> *)symbolsOfLinkMapFile:(NSString *)file combination:(BOOL)combination keyword:(NSString *)keyword {
    if (!isFilePath(file)) {
        return nil;
    }
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSMacOSRomanStringEncoding error:nil];
    return symbolsFromContent(content, combination, keyword);
}

static BOOL isFilePath(NSString *path) {
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return isExists && !isDirectory;
}

static NSArray<LinkSymbol *> *symbolsFromContent(NSString *content, BOOL combination, NSString *keyword) {
    NSArray<LinkSymbol *> *symbols = nil;
    if (checkContent(content)) {
        NSDictionary *symbolMap = symbolMapFromContent(content);
        symbols = [symbolMap allValues];
        
        if (combination) {
            symbols = combinationSymbols(symbols);
        }
        else {
            symbols = sortSymbols(symbols);
        }
        
        if (keyword.length > 0) {
            symbols = searchSymbols(symbols, keyword);
        }
    }
    return symbols;
}


static BOOL checkContent(NSString *content) {
    if (content.length == 0) {
        return NO;
    }
    NSRange objsFileTagRange = [content rangeOfString:@"# Object files:"];
    if (objsFileTagRange.length == 0) {
        return NO;
    }
    NSString *subObjsFileSymbolStr = [content substringFromIndex:objsFileTagRange.location + objsFileTagRange.length];
    NSRange symbolsRange = [subObjsFileSymbolStr rangeOfString:@"# Symbols:"];
    if ([content rangeOfString:@"# Path:"].length <= 0||objsFileTagRange.location == NSNotFound||symbolsRange.location == NSNotFound) {
        return NO;
    }
    return YES;
}

NSDictionary *symbolMapFromContent(NSString *content) {
    NSMutableDictionary <NSString *,LinkSymbol *>*symbolMap = [NSMutableDictionary dictionary];
    // 符号文件列表
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    
    BOOL reachFiles = NO;
    BOOL reachSymbols = NO;
    BOOL reachSections = NO;
    
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"])
                reachFiles = YES;
            else if ([line hasPrefix:@"# Sections:"])
                reachSections = YES;
            else if ([line hasPrefix:@"# Symbols:"])
                reachSymbols = YES;
        } else {
            if(reachFiles == YES && reachSections == NO && reachSymbols == NO) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    LinkSymbol *symbol = [LinkSymbol new];
                    symbol->_file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                }
            } else if (reachFiles == YES && reachSections == YES && reachSymbols == YES) {
                NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                if(symbolsArray.count == 3) {
                    NSString *fileKeyAndName = symbolsArray[2];
                    NSUInteger size = strtoul(symbolsArray[1].UTF8String, nil, 16);
                    
                    NSRange range = [fileKeyAndName rangeOfString:@"]"];
                    if(range.location != NSNotFound) {
                        NSString *key = [fileKeyAndName substringToIndex:range.location+1];
                        LinkSymbol *symbol = symbolMap[key];
                        if(symbol) {
                            symbol->_size += size;
                        }
                    }
                }
            }
        }
    }
    return [symbolMap copy];
}


static NSDictionary<NSString *, NSArray<LinkSymbol *> *> *groupingSymbols(NSArray<LinkSymbol *> *symbols) {
    if (symbols.count == 0) {
        return nil;
    }
    NSMutableDictionary<NSString *, NSMutableArray<LinkSymbol *> *> *groupingMap = [NSMutableDictionary dictionary];
    
    for(LinkSymbol *symbol in symbols) {
        NSString *name = symbol.file.lastPathComponent;
        NSString *group = name;
        NSArray *names = matche(@"(.*(?=\\())|((?<=\\().*(?=\\)))", name);
        if (names.count > 1) {
            group = names.firstObject;
            name = names.lastObject;
        }
        
        NSMutableArray *symbolArr = groupingMap[group];
        if (!symbolArr) {
            symbolArr = [NSMutableArray array];
            groupingMap[group] = symbolArr;
        }
        
        LinkSymbol *childSymbol = [[LinkSymbol alloc] init];
        childSymbol->_file = symbol.file;
        childSymbol->_size = symbol.size;
        childSymbol->_name = name;
        [symbolArr addObject:childSymbol];
    }
    
    return [groupingMap copy];
}

static NSArray<LinkSymbol *> *combinationSymbols(NSArray<LinkSymbol *> *symbols) {
    NSDictionary<NSString *, NSArray<LinkSymbol *> *> *groupingMap = groupingSymbols(symbols);
    NSMutableArray *combinationSymbols = [NSMutableArray array];
    for (NSString *combination in groupingMap.allKeys) {
        NSArray<LinkSymbol *> *symbols = groupingMap[combination];
        if (symbols.count > 1) {
            symbols = sortSymbols(symbols);
            NSUInteger size = 0;
            for (LinkSymbol *symbol in symbols) {
                size += symbol.size;
            }
            LinkSymbol *symbol = [[LinkSymbol alloc] init];
            symbol->_file = combination;
            symbol->_size = size;
            symbol->_name = combination;
            symbol->_childs = symbols;
            [combinationSymbols addObject:symbol];
        }
        else {
            [combinationSymbols addObject:symbols.firstObject];
        }
    }
    return sortSymbols(combinationSymbols);
}


static NSArray<LinkSymbol *> *sortSymbols(NSArray<LinkSymbol *> *symbols) {
    return [symbols sortedArrayUsingComparator:^NSComparisonResult(LinkSymbol *  _Nonnull obj1, LinkSymbol *  _Nonnull obj2) {
        if(obj1.size > obj2.size) {
            return NSOrderedAscending;
        } else if (obj1.size < obj2.size) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

static NSArray<LinkSymbol *> *searchSymbols(NSArray<LinkSymbol *> *symbols, NSString *keywork) {
    NSMutableArray *searchedSymbols = [NSMutableArray array];
    for(LinkSymbol *symbol in symbols) {
        if ([symbol.file containsString:keywork]) {
            [searchedSymbols addObject:symbol];
        }
    }
    return [searchedSymbols copy];
}

static NSArray<NSString *> *matche(NSString *regex, NSString *string) {
    NSError *error = NULL;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regularExpression matchesInString:string options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators range:NSMakeRange(0, string.length)];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSTextCheckingResult *matche in matches) {
        if (matche.range.length > 0) {
            NSString *str = [string substringWithRange:matche.range];
            [arr addObject:str];
        }
    }
    return [arr copy];
}

@end
