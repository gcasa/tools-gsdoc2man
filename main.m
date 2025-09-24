/* File: main.m
   Path: src/main.m
*/
#import <Foundation/Foundation.h>
#import "GSDocToMan.h"

static NSString *SAMPLE_GSDOC = @"<?xml version=\"1.0\"?>\n"
"<gsdoc>\n"
"  <title>sampletool</title>\n"
"  <shortdesc>A demo tool that prints things</shortdesc>\n"
"  <synopsis>sampletool [options] &lt;file&gt;</synopsis>\n"
"  <section>\n"
"    <title>Description</title>\n"
"    <p>SampleTool demonstrates converting a simple &lt;gsdoc&gt; XML to a groff manpage.\n"
"       Use <code>sampletool</code> to print demo output.</p>\n"
"  </section>\n"
"  <options>\n"
"    <option>\n"
"      <flag>-h, --help</flag>\n"
"      <desc>Show help and exit.</desc>\n"
"    </option>\n"
"    <option>\n"
"      <flag>-v, --version</flag>\n"
"      <desc>Show version number.</desc>\n"
"    </option>\n"
"  </options>\n"
"  <examples>\n"
"    <example>\n"
"      <pre>sampletool -h\n"
"# shows help</pre>\n"
"    </example>\n"
"  </examples>\n"
"</gsdoc>\n";

int main(int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *inputPath = nil;
    NSString *outputPath = nil;
    NSString *section = @"1";
    NSString *manual = @"";
    NSString *date = nil;
    BOOL testMode = NO;

    // Simple arg parsing
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (strcmp(a, "-i") == 0 && i+1 < argc) { inputPath = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "--input") == 0 && i+1 < argc) { inputPath = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "-o") == 0 && i+1 < argc) { outputPath = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "--output") == 0 && i+1 < argc) { outputPath = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "-s") == 0 && i+1 < argc) { section = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "-m") == 0 && i+1 < argc) { manual = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "--date") == 0 && i+1 < argc) { date = [NSString stringWithUTF8String:argv[++i]]; continue; }
        if (strcmp(a, "--test") == 0) { testMode = YES; continue; }
        if (strcmp(a, "--help") == 0 || strcmp(a, "-h") == 0) {
            printf("Usage: gsdoc_to_man -i input.gsdoc -o output.1 -s 1 -m ManualName --date YYYY-MM-DD --test\n");
            [pool drain];
            return 0;
        }
    }

    if (testMode) {
        // parse sample string by writing to temporary data and using conversion helper expecting file or stdin
        NSData *data = [SAMPLE_GSDOC dataUsingEncoding:NSUTF8StringEncoding];
        // we will write to a temp file so convertFileAtPath can read it
        NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"sample_gsdoc.xml"];
        [data writeToFile:tmp atomically:YES];
        int rc = [GSDocToMan convertFileAtPath:tmp outPath:outputPath section:section manual:manual date:date];
        [[NSFileManager defaultManager] removeItemAtPath:tmp error:NULL];
        [pool drain];
        return rc;
    }

    int rc = [GSDocToMan convertFileAtPath:inputPath outPath:outputPath section:section manual:manual date:date];
    [pool drain];
    return rc;
}
