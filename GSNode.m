/* File: src/GSNode.m */
#import "GSNode.h"

@implementation GSNode

- (id)initWithName:(NSString *)aName attrs:(NSDictionary *)attrs
{
  self = [super init];
  if (self) {
    if (aName)
      name = [aName retain];
    else
      name = [@"" retain];
    if (attrs)
      attributes = [[NSMutableDictionary alloc] initWithDictionary:attrs];
    else
      attributes = [[NSMutableDictionary alloc] init];
    text = [[NSMutableString alloc] init];
    children = [[NSMutableArray alloc] init];
    }
  return self;
}

+ (GSNode *)nodeWithName:(NSString *)aName attrs:(NSDictionary *)attrs
{
  GSNode *n = [[[GSNode alloc] initWithName:aName attrs:attrs] autorelease];
  return n;
}

- (void)dealloc
{
  [name release];
  [attributes release];
  [text release];
  [children release];
  [super dealloc];
}

- (void)addChild:(GSNode *)child
{
  if (child)
    [children addObject:child];
}

- (void)appendText:(NSString *)chunk
{
  if (chunk && [chunk length] > 0)
    [text appendString:chunk];
}

- (GSNode *)firstChildNamed:(NSString *)childName
{
  if (!childName) return nil;
  NSEnumerator *en = [children objectEnumerator];
  GSNode *c;
  while ((c = [en nextObject])) {
    if ([[[c->name lowercaseString]
	   stringByTrimmingCharactersInSet:
	     [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:
		   [[childName lowercaseString] stringByTrimmingCharactersInSet:
						  [NSCharacterSet whitespaceAndNewlineCharacterSet]]])
      return c;
  }
  return nil;
}

- (NSString *)textForChildNamed:(NSString *)childName
{
  GSNode *c = [self firstChildNamed:childName];
  if (c && [c->text length])
    return [NSString stringWithString:[c->text stringByTrimmingCharactersInSet:
					  [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
  return nil;
}

- (NSArray *)children
{
  return children;
}

- (NSString *)name
{
  return name;
}

- (NSString *)text
{
  return text;
}

- (NSMutableDictionary *) attributes
{
  return attributes;
}

@end
