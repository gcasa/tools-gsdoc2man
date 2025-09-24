/* File: src/GSXMLBuilder.h */
#import <Foundation/Foundation.h>
#import "GSNode.h"

@interface GSXMLBuilder : NSObject <NSXMLParserDelegate>
{
    NSMutableArray *stack;
    GSNode *rootNode;
}

- (GSNode *)rootNode;

@end
