/* File: src/GSXMLBuilder.m */
#import "GSXMLBuilder.h"

@implementation GSXMLBuilder

- (id)init
{
    self = [super init];
    if (self) {
        stack = [[NSMutableArray alloc] init];
        rootNode = nil;
    }
    return self;
}

- (void)dealloc
{
    [stack release];
    [rootNode release];
    [super dealloc];
}

- (GSNode *)rootNode
{
    return rootNode;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    GSNode *n = [GSNode nodeWithName:elementName attrs:attributeDict];
    if ([stack count] == 0) {
        [rootNode release];
        rootNode = [n retain];
        [stack addObject:rootNode];
    } else {
        GSNode *parent = [stack lastObject];
        [parent addChild:n];
        [stack addObject:n];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([stack count] > 0) {
        [stack removeLastObject];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ([stack count] > 0) {
        GSNode *cur = [stack lastObject];
        [cur appendText:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // parse errors are handled by caller checking parser.parse return
}

@end

