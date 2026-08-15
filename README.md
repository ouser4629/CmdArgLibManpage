<!-- 
//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.
-->

## CmdArgLibManpage

CmdArgLibManpage is part of the [Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git).

It provides a "meta-flag" constructor that can be used to generate manpages.

---

## Usage

Declare an array
of [`ShowElements`](https://github.com/ouser4629/cmd-arg-lib/blob/main/REFERENCE.md#show-elements) that
defines your manual page:

```
static let manpageLayout: [ShowElement] = [ ... ]
```

If you are using the library's macro-based API, add the following parameter to the annotated command function:

```
generateManpage: MetaFlag = MetaFlag(manpageElements: manpageLayout)
```

If you are using the library's struct-based API, add the following variable to the conforming struct:

```
var generateManpage: MetaFlag = MetaFlag(manpageElements: manpageLayout)
```

If "--generateManpage" is encountered in a command argument list, the manual page defined by `manpageLayout` will be 
generated and written to stdout.

---

## Sample

<details>
<summary>Code</summary>

```swift
import CmdArgLibCore
import CmdArgLibMacros
import CmdArgLibManpage 

typealias Greeting = String
typealias Name = String
typealias Count = Int

@main
struct Main {

    @MainFunctionMacro(shadowGroups: ["lower upper"])
    private static func printM1(
        i includeIndex: Flag,
        u upper: Flag,
        l lower: Flag,
        c__count repeats: Count?,
        g__greeting greeting: Greeting = "Hello",
        _ name: Name,
        generateManpage: MetaFlag = MetaFlag(manpageElements: manpageElements),
        v__version version: MetaFlag = MetaFlag(string: "version 0.1.0"))
    {
        let count = repeats == nil || repeats! < 1 ? (Int.random(in: 1...3)) : repeats!
        var text = "\(greeting) \(name)"
        text = lower ? text.lowercased() : upper ? text.uppercased() : text
        for index in 1...count {
            var text = (includeIndex ? "\(index) " : "") + "\(greeting) \(name)"
            if upper { text = text.uppercased() }
            print(text)
        }
    }
    
    static let manpageElements: [ShowElement] = [ ... ]
}
```

</details>

<details>
<summary>Manpage Elements</summary>

```swift
extension Main {
    
    private static let manpageElements: [ShowElement] = [
        .prologue(description: "print a greeting."),
        .synopsis(),
        .mdoc("DESCRIPTION", "Print $T{greeting}, followed by $E{name}, $E{repeats} times."),
        .mdoc("", "The following options are available:"),
        .parameter("greeting", "The greeting to print"),
        .parameter("includeIndex", "Show index of repeated greetings"),
        .parameter("lower", "Print text in lower case"),
        .parameter("repeats", "Repeat the greeting $E{repeats} times (the default is a random integer between 1 and 3)"),
        .parameter("upper", "Print text in upper case"),
        .parameter("generateManpage", "Generate this manual page"), 
        .parameter("version", "Show version information"),
        .mdoc("", note1),
        .mdoc("", exitStatus),
        .mdoc("", examples),
        .mdoc("", seeAlso),
        .mdoc("", authors),
    ]

    private static let note1 = """
        The $S{lower} and $S{upper} options shadow each other; only the last one specified
        is applicable.
        """

    private static let exitStatus = """
        .Sh EXIT STATUS
        The 
        .Nm
        utility exits 0 on success, and >0 if an error occurs.
        """

    private static let examples = """
        .Sh EXAMPLES
        .Pp
        Say 'Hi' to John Wesley Harding:
        .Pp
        .Dl > print-m1 -c1 -g Hi 'John Wesley Harding'
        .Pp
        Say it twice with an index:
        .Pp
        .Dl > print-m1 -ic2 -g Hi 'John Wesley Harding'
        """

    private static let seeAlso = """
        .Sh SEE ALSO
        .Xr man 1 ,
        .Xr mandoc 1 ,
        .Xr sed 1 ,
        .Xr mdoc 7 ,
        .Xr re_format 7
        """

    private static let authors = """
        .Sh AUTHORS
        The 
        .Nm
        utility was written by
        .%A Mack the Finger and Louie the King .
        """

    private static let mammalDict: [String: String] = [
        "cat": "A domesticated carnivorous mammal.",
        "dog": "A domesticated carnivorous mammal.",
        "cow": "A large, domesticated bovine mammal.",
    ]
}
```

</details>

<details>
<summary>Generated Mdoc Source</summary>

```
.Dd August 14, 2026
.Dt PRINT-M1 1
.Os 
.Sh NAME
.Nm print-m1
.Nd print a greeting.
.Sh SYNOPSIS
.Nm print-m1
[-iulv]
.Eo \&[  Fl c Ar count Ec ]
.Eo \&[  Fl g Ar greeting Ec ]
.Ar name
.Op Fl -generate-manpage
.Sh DESCRIPTION
Print 
.Ar greeting Ns , followed by 
.Ar name Ns , 
.Ar count No  times.
.Pp
The following options are available:
.Bl -tag -width indent
.It Fl g, Fl -greeting Ar greeting
The greeting to print (default: "Hello").
.It Fl i
Show index of repeated greetings.
.It Fl l
Print text in lower case.
.It Fl c, Fl -count Ar count
Repeat the greeting 
.Ar count No  times (the default is a random integer between 1 and 3).
.It Fl u
Print text in upper case.
.It Fl -generate-manpage
Generate this manual page.
.It Fl v, Fl -version
Show version information.
.El
.Pp
The 
.Fl l No  and 
.Fl u No  options shadow each other; only the last one specified
is applicable.
.Pp
.Sh EXIT STATUS
The 
.Nm
utility exits 0 on success, and >0 if an error occurs.
.Pp
.Sh EXAMPLES
.Pp
Say 'Hi' to John Wesley Harding:
.Pp
.Dl > print-m1 -c1 -g Hi 'John Wesley Harding'
.Pp
Say it twice with an index:
.Pp
.Dl > print-m1 -ic2 -g Hi 'John Wesley Harding'
.Pp
.Sh SEE ALSO
.Xr man 1 ,
.Xr mandoc 1 ,
.Xr sed 1 ,
.Xr mdoc 7 ,
.Xr re_format 7
.Pp
.Sh AUTHORS
The 
.Nm
utility was written by
.%A Mack the Finger and Louie the King .
```



</details>

---

### Examples

[Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git) has extensive examples
that show how to use `CmdArgLibManpage`.

## Project Status

This software is licensed under the [Mozilla Public License, v. 2.0 "MPL-2.0"](https://mozilla.org/MPL/2.0).

It is currently in beta (version 0.5.0), and has only been tested for macOS.

---
