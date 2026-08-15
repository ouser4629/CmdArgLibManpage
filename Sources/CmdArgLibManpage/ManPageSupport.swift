//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

func mdocTypeNameOf(_ parameter: Parameter) -> String
{
    var typeName = parameter.standardTypeName
    if typeName.hasSuffix("...") {
        typeName.removeLast(3)
    } else if typeName.hasPrefix("[") && typeName.hasSuffix("]") {
        typeName.removeFirst(1)
        typeName.removeLast(1)
    } else if typeName.hasSuffix("?") {
        typeName.removeLast()
    } else if typeName.hasPrefix("MetaOption<") && typeName.hasSuffix(">") {
        typeName.removeFirst(11)
        typeName.removeLast(1)
    }
    return SymbolFormatter.snake(typeName, "_")
}

func programNameFor(_ callNames: [String]) -> String
{
    callNames.joined(separator: "-")
}
