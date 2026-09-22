// Copyright (c) 2025-2026 Peter Summerland LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
