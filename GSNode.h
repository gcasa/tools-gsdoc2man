/* File: src/GSNode.h */
#import <Foundation/Foundation.h>

@interface GSNode : NSObject
{
    NSString *name;
    NSMutableDictionary *attributes;
    NSMutableString *text;
    NSMutableArray *children;
}

- (id)initWithName:(NSString *)aName attrs:(NSDictionary *)attrs;
+ (GSNode *)nodeWithName:(NSString *)aName attrs:(NSDictionary *)attrs;

- (void)addChild:(GSNode *)child;
- (void)appendText:(NSString *)chunk;
- (GSNode *)firstChildNamed:(NSString *)childName;
- (NSString *)textForChildNamed:(NSString *)childName;
- (NSArray *)children;
- (NSString *)name;
- (NSString *)text;
- (NSMutableDictionary *)attributes;

@end
