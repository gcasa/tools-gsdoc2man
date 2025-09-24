/* File: GSDocToMan.h
   Path: src/GSDocToMan.h
*/
#import <Foundation/Foundation.h>
#import "GSNode.h"

@interface GSDocToMan : NSObject
{
    NSString *section;
    NSString *manual;
    NSString *dateString;
    NSMutableString *out;
}

- (instancetype)initWithSection: (NSString *)sec
                         manual: (NSString *)man
                           date: (NSString *)date;

- (NSString *)convertNode: (GSNode *)root;

+ (int)convertFileAtPath: (NSString *)inPath
                 outPath: (NSString *)outPath
                 section: (NSString *)sec
                  manual: (NSString *)man
                    date: (NSString *)date;

@end
