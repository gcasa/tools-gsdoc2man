# tools-gsdoc2man

`gsdoc2man` is a command-line utility that converts **GNUstep .gsdoc XML
documentation files** into **groff manpages**.  
It is written in **Objective-C 1.0** and designed to conform to the
**GNU Coding Standards**.  
The tool is built on top of GNUstep’s Foundation library and avoids all
Objective-C 2.0 features for maximum portability.

---

## Features

- Parses `.gsdoc` XML documents into an internal tree representation.
- Generates clean, portable **groff manpage output**.
- Supports common `.gsdoc` elements:
  - `<title>`, `<shortdesc>`, `<section>`, `<subsection>`
  - `<para>`, `<pre>`, `<example>`, `<list>`, `<item>`
  - `<options>`, `<option>`, `<flag>`, `<arg>`
- Produces proper `.TH`, `.SH`, `.SS`, `.PP`, `.TP` macros.
- Escapes groff-sensitive characters to avoid rendering errors.
- Command-line options follow GNU conventions:
  - `--help`
  - `--version`

---

## Requirements

- GNUstep Base Library (`libgnustep-base`)
- GNUstep Make (`gnustep-make`)
- A C compiler with Objective-C 1.0 support (e.g., GCC with `-fobjc-runtime=gnustep-1.0`)

---

## Building

With GNUstep Make:

```sh
. /usr/share/GNUstep/Makefiles/GNUstep.sh
make
