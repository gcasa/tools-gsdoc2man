/* File: GSDocToMan.m
   Path: src/GSDocToMan.m
*/
#import "GSDocToMan.h"
#import "GSXMLBuilder.h"

@implementation GSDocToMan

- (instancetype)initWithSection:(NSString *)sec manual:(NSString *)man date:(NSString *)date
{
  self = [super init];
  if (self)
    {
      section = [sec copy]; manual = [man copy]; dateString = [date copy];
      if (!dateString)
	{
	  NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	  [df setDateFormat:@"yyyy-MM-dd"];
	  dateString = [[df stringFromDate:[NSDate date]] retain];
	}
      out = [[NSMutableString alloc] init];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(section);
  RELEASE(manual);
  RELEASE(dateString);
  RELEASE(out);

  [super dealloc];
}

/* Helpers */
- (NSString *)escapeManText:(NSString *)s
{
  if (!s)
    {
      return @"";
    }
  
  // Replace backslash with double backslash and protect leading dot on lines.
  NSMutableString *m = [NSMutableString stringWithString:s];
  [m replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, [m length])];

  // parse lines...
  NSArray *lines = [m componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:[lines count]];
  NSEnumerator *en = [lines objectEnumerator];
  NSString *ln = nil;

  while ((ln = [en nextObject]))
    {
      if ([ln length] > 0 && [ln hasPrefix:@"."])
	{
	  [newLines addObject:[@"\\&" stringByAppendingString:ln]];
	}
      else
	{
	  [newLines addObject:ln];
	}
    }

  return [newLines componentsJoinedByString:@"\n"];
}

- (NSString *)trim:(NSString *)s
{
  if (!s) return @"";
  return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)upper:(NSString *)s
{
  if (!s) return @"";
  return [s uppercaseString];
}

- (void)appendLine:(NSString *)line
{
  if (line)
    [out appendFormat:@"%@\n", line];
}

/* Preamble */
- (void)writeTHWithTitle:(NSString *)title
{
  NSString *t = [self upper:[self trim:title]];
  NSString *m = manual ? manual : @"";
  [self appendLine:[NSString stringWithFormat:@".TH \"%@\" \"%@\" \"%@\" \"%@\"",
			  [self escapeManText:t],
			  [self escapeManText:section],
			  [self escapeManText:dateString],
			  [self escapeManText:m]]];
}

- (NSString *)renderInlinesForNode:(GSNode *)el
{
  NSMutableString *buf = [NSMutableString string];
  if ([[el text] length])
    {
      [buf appendString:[self escapeManText:[el text]]];
    }

  NSArray *children = [el children];
  NSEnumerator *en = [children objectEnumerator];
  GSNode *child = nil;
  
  while ((child = [en nextObject]))
    {
      NSString *t = [[[child name] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      NSString *inner = [self renderInlinesForNode:child];
      if ([t isEqualToString:@"b"] || [t isEqualToString:@"strong"]) {
	[buf appendFormat:@"\\fB%@\\fP", inner];
      } else if ([t isEqualToString:@"i"] || [t isEqualToString:@"em"]) {
	[buf appendFormat:@"\\fI%@\\fP", inner];
      } else if ([t isEqualToString:@"code"] || [t isEqualToString:@"tt"] || [t isEqualToString:@"kbd"]) {
	[buf appendFormat:@"\\f(CW%@\\fP", inner];
      } else if ([t isEqualToString:@"a"] || [t isEqualToString:@"link"] || [t isEqualToString:@"ref"]) {
	NSString *href = [child.attributes objectForKey:@"href"];
	if (!href) href = [child.attributes objectForKey:@"ref"];
	NSString *text = [self trim:inner];
	if (href && [href length]) {
	  if (text && [text length]) {
	    if ([href rangeOfString:text].location == NSNotFound)
	      [buf appendFormat:@"%@ (%@)", text, href];
	    else
	      [buf appendString:text];
	  } else {
	    [buf appendString:href];
	  }
	} else {
	  [buf appendString:inner];
	}
      } else if ([t isEqualToString:@"br"]) {
	[buf appendString:@"\n"];
      } else {
	[buf appendString:inner];
      }
      if ([child.text length] == 0 && child != [el.children lastObject] && [child.children count] == 0) {
	// nothing
      }
      if ([[child text] length] > 0) {
	// child.tail not available; we rely on child.text + next child's text
      }
    }
    return buf;
}

/* Dedent preformatted text */
- (NSString *)dedentText:(NSString *)s
{
  if (!s)
    {
      return @"";
    }
  
  NSArray *lines = [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSUInteger minIndent = NSNotFound;
  NSString *ln = nil;
  NSEnumerator *en = [lines objectEnumerator];
  
  while ((ln = [en nextObject]))
    {
      NSString *trim = [ln stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      if ([trim length] == 0) continue;
      NSUInteger i = 0;
      while (i < [ln length] && [ln characterAtIndex:i] == ' ') i++;
      if (minIndent == NSNotFound || i < minIndent) minIndent = i;
    }
  
  if (minIndent == NSNotFound || minIndent == 0)
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  NSMutableArray *outLines = [NSMutableArray arrayWithCapacity:[lines count]];
  en = [lines objectEnumerator];
  ln = nil;
  while ((ln = [en nextObject]))
    {
      if ([ln length] >= minIndent) {
	[outLines addObject:[ln substringFromIndex:minIndent]];
      } else {
	[outLines addObject:ln];
      }
    }
  return [[outLines componentsJoinedByString:@"\n"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/* Block handlers */
- (void)handleBlockNode:(GSNode *)el
{
  NSString *tag = [[[el name] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if ([tag isEqualToString:@"section"] || [tag isEqualToString:@"sect"] || [tag isEqualToString:@"sec"])
    {
      NSString *title = [self trim:[el textForChildNamed:@"title"]];
      if (!title) title = [self trim:[el textForChildNamed:@"name"]];
      if (title) [self appendLine:[NSString stringWithFormat:@".SH %@", [self escapeManText:title]]];
      for (GSNode *c in [el children]) [self handleBlockNode:c];
    }
  else if ([tag isEqualToString:@"subsection"] || [tag isEqualToString:@"subsect"])
    {
      NSString *title = [self trim:[el textForChildNamed:@"title"]];
      if (!title) title = [self trim:[el textForChildNamed:@"name"]];
      if (title) [self appendLine:[NSString stringWithFormat:@".SS %@", [self escapeManText:title]]];
      for (GSNode *c in [el children]) [self handleBlockNode:c];
    }
  else if ([tag isEqualToString:@"p"] || [tag isEqualToString:@"para"] || [tag isEqualToString:@"paragraph"])
    {
      [self appendLine:@".PP"];
      NSString *inl = [self trim:[self renderInlinesForNode:el]];
      if ([inl length]) [self appendLine:[self escapeManText:inl]];
    }
  else if ([tag isEqualToString:@"synopsis"])
    {
      [self appendLine:@".SH SYNOPSIS"];
      NSString *text = [self trim:[self renderInlinesForNode:el]];
      if ([text length])
	{
	  [self appendLine:@".nf"];
	  [self appendLine:[self escapeManText:text]];
	  [self appendLine:@".fi"];
	}
    }
  else if ([tag isEqualToString:@"pre"] || [tag isEqualToString:@"verbatim"] || [tag isEqualToString:@"codeblock"] || [tag isEqualToString:@"example"])
    {
      NSString *txt = [self dedentText: [el text]];
      if ([txt length] == 0)
	{
	  // maybe children contain code nodes
	  NSMutableArray *pieces = [NSMutableArray array];
	  for (GSNode *c in [el children])
	    {
	      if ([c.text length]) [pieces addObject:c.text];
	    }
	  txt = [pieces componentsJoinedByString:@"\n"];
	}
      [self appendLine:@".PP"];
      [self appendLine:@".nf"];
      for (NSString *ln in [txt componentsSeparatedByString:@"\n"])
	{
	  [self appendLine:[self escapeManText:ln]];
	}
      [self appendLine:@".fi"];
    }
  else if ([tag isEqualToString:@"examples"])
    {
      [self appendLine:@".SH EXAMPLES"];
      GSNode *c = nil;
      NSArray *children = [el children];
      NSEnumerator *en = [children objectEnumerator];
      while ((c = [en nextObject])) [self handleBlockNode:c];
    }
  else if ([tag isEqualToString:@"list"] || [tag isEqualToString:@"ul"] || [tag isEqualToString:@"ol"])
    {
      for (GSNode *li in [el children])
	{
	  NSString *nt = [[li.name lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	  if (![nt isEqualToString:@"li"] && ![nt isEqualToString:@"item"]) continue;

	  // detect label term child
	  GSNode *term = [li firstChildNamed:@"term"];
	  NSString *label = nil;
	  NSString *body = nil;
	  if (term)
	    {
	      label = [self trim:[self renderInlinesForNode:term]];
	      // assemble rest as body
	      NSMutableArray *parts = [NSMutableArray array];
	      for (GSNode *c in li.children) {
		if (c != term) {
		  NSString *r = [self trim:[self renderInlinesForNode:c]];
		  if ([r length]) [parts addObject:r];
		}
	      }
	      body = [parts componentsJoinedByString:@" "];
	    }
	  else
	    {
	      label = @"\\(bu";
	      body = [self trim:[self renderInlinesForNode:li]];
	    }
	  [self appendLine:[NSString stringWithFormat:@".IP \"%@\"", [self escapeManText:label]]];
	  if ([body length]) [self appendLine:[self escapeManText:body]];
	}
    }
  else if ([tag isEqualToString:@"options"])
    {
      [self appendLine:@".SH OPTIONS"];
      for (GSNode *c in [el children]) [self handleBlockNode:c];
    }
  else if ([tag isEqualToString:@"option"] || [tag isEqualToString:@"opt"])
    {
      // collect flags and desc
      NSMutableArray *flags = [NSMutableArray array];
      NSMutableArray *descparts = [NSMutableArray array];
      GSNode *c = nil;
      NSArray *children = [el children];
      NSEnumerator *en = [children objectEnumerator];
      while ((c = [en nextObject]))
	{
	  NSString *t = [c.name lowercaseString];
	  if ([t isEqualToString:@"flag"] || [t isEqualToString:@"name"] || [t isEqualToString:@"short"] || [t isEqualToString:@"long"] || [t isEqualToString:@"opt"])
	    {
	      NSString *r = [self trim:[self renderInlinesForNode:c]];
	      if ([r length]) [flags addObject:r];
	    }
	  else if ([t isEqualToString:@"arg"] || [t isEqualToString:@"argument"])
	    {
	      NSString *r = [self trim:[self renderInlinesForNode:c]];
	      if ([r length]) [flags addObject:r];
	    }
	  else if ([t isEqualToString:@"desc"] || [t isEqualToString:@"description"] || [t isEqualToString:@"summary"])
	    {
	      NSString *r = [self trim:[self renderInlinesForNode:c]];
	      if ([r length]) [descparts addObject:r];
	    }
	  else
	    {
	      NSString *r = [self trim:[self renderInlinesForNode:c]];
	      if ([r length]) [descparts addObject:r];
	    }
	}
      if ([[el text] length]) [descparts insertObject:[self trim:[el text]] atIndex:0];
      NSString *label = ([flags count] ? [flags componentsJoinedByString:@" "] : [[self renderInlinesForNode:el] substringToIndex:MIN(40, [[self renderInlinesForNode:el] length])]);
      [self appendLine:@".TP"];
      // use .BR style for label
      [self appendLine:[NSString stringWithFormat:@".BR %@", [self escapeManText:label]]];
      NSString *desc = ([descparts count] ? [descparts componentsJoinedByString:@" "] : @"");
      if ([desc length]) [self appendLine:[self escapeManText:desc]];
    }
  else if ([tag isEqualToString:@"title"] || [tag isEqualToString:@"name"])
    {
      // skip here (handled in header)
    }
  else
    {
      // fallback: if has block-like children, recurse; else treat as paragraph
      BOOL hasBlock = NO;
      NSArray *children = [el children];
      NSEnumerator *en = [children objectEnumerator];
      GSNode *c = nil;
      
      while ((c = [en nextObject]))
	{
	  NSString *tn = [[c.name lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	  if ([tn isEqualToString:@"section"]
	      || [tn isEqualToString:@"p"]
	      || [tn isEqualToString:@"pre"]
	      || [tn isEqualToString:@"list"]
	      || [tn isEqualToString:@"options"]
	      || [tn isEqualToString:@"synopsis"])
	    {
	      hasBlock = YES;
	      break;
	    }
	}
      
      if (hasBlock)
	{
	  NSArray *children = [el children];
	  NSEnumerator *en = [children objectEnumerator];
	  GSNode *c = nil;
	  while ((c = [en nextObject]))
	    {
	      [self handleBlockNode:c];
	    }
	}
      else
	{
	  NSString *inl = [self trim:[self renderInlinesForNode:el]];
	  if ([inl length])
	    {
	      [self appendLine:@".PP"];
	      [self appendLine:[self escapeManText:inl]];
	    }
	}
    }
}

/* Top-level conversion */
- (NSString *)convertNode:(GSNode *)root
{
  // find title and shortdesc
  NSString *title = nil;
  NSString *shortname = nil;
  GSNode *t = [root firstChildNamed:@"title"];

  if (t && [t.text length]) title = [self trim:t.text];
  if (!title) title = [[root attributes] objectForKey: @"title"];
  if (!title) title = [[root attributes] objectForKey: @"name"];
  if (!title) title = @"UNKNOWN";
  GSNode *s = [root firstChildNamed: @"shortdesc"];
  if (s && [s.text length]) shortname = [self trim: [s text]];
  // header
  [self writeTHWithTitle: title];
  // NAME section
  [self appendLine: @".SH NAME"];
  NSString *nameEntry = nil;
  if (shortname)
    {
      nameEntry = [NSString stringWithFormat:@"%@ \\- %@", [self escapeManText:[title lowercaseString]], [self escapeManText:shortname]];
    }
  else
    {
      nameEntry = [NSString stringWithFormat:@"%@ \\- %@", [self escapeManText:[title lowercaseString]], [self escapeManText:title]];
    }
  
  [self appendLine:nameEntry];
  // find body wrapper
  GSNode *body = nil;
  NSArray *children = [root children];
  NSEnumerator *en = [children objectEnumerator];
  GSNode *c = nil;
  while ((c = [en nextObject]))
    {
      NSString *n = [[[c name] lowercaseString] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if ([n isEqualToString:@"body"] || [n isEqualToString:@"content"] || [n isEqualToString:@"document"]) { body = c; break; }
    }

  if (!body) body = root;
  children = [body children];
  en = [children objectEnumerator];
  while ((c = [en nextObject]))
    {
      [self handleBlockNode: c];
    }
  return out;
}

/* File conversion helper */
+ (int)convertFileAtPath:(NSString *)inPath outPath:(NSString *)outPath section:(NSString *)sec manual:(NSString *)man date:(NSString *)date
{
  NSData *data = nil;
  if (inPath)
    {
      data = [NSData dataWithContentsOfFile:inPath];
      if (!data)
	{
	  fprintf(stderr, "Cannot read input file %s\n", [inPath UTF8String]);
	  return 1;
	}
    }
  else
    {
      // read stdin
      NSMutableData *buf = [NSMutableData data];
      char chunk[4096];
      ssize_t r;
      while ((r = read(STDIN_FILENO, chunk, sizeof(chunk))) > 0)
	{
	  [buf appendBytes:chunk length:r];
	}
      data = buf;
    }

  NSXMLParser *parser = [[NSXMLParser alloc] initWithData: data];
  GSXMLBuilder *builder = [[[GSXMLBuilder alloc] init] autorelease];
  [parser setDelegate:builder];
  BOOL ok = [parser parse];
  if (!ok)
    {
      NSError *err = [parser parserError];
      fprintf(stderr, "XML parse error: %s\n", [[err localizedDescription] UTF8String]);
      return 2;
    }
  
  GSNode *root = [builder rootNode];
  if (!root)
    {
      fprintf(stderr, "No root node found in XML\n");
      return 3;
    }
  GSDocToMan *conv = [[[GSDocToMan alloc] initWithSection:(sec?sec:@"1") manual:(man?man:@"") date:date] autorelease];
  NSString *outStr = [conv convertNode:root];
  if (outPath)
    {
      NSError *err = nil;
      BOOL wrote = [outStr writeToFile:outPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
      if (!wrote)
	{
	  fprintf(stderr, "Error writing output: %s\n", [[err localizedDescription] UTF8String]);
	  return 4;
	}
    }
  else
    {
      fwrite([outStr UTF8String], 1, [outStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding], stdout);
    }

  return 0;
}

@end
