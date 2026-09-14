//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

struct ManpageExpander {
    let showMacro: ShowMacro
    let hotChar = ShowMacro.hotChar
    let parameterWithName: [String: Parameter]
    let callNames: [String]

    init(callNames: [String], context: RunContext)
    {
        var dictionary = [String: Parameter]()
        for parameter in context.parameters {
            dictionary[parameter.name] = parameter
        }
        self.parameterWithName = dictionary
        self.showMacro = ShowMacro(callNames: callNames)
        self.callNames = callNames
    }

    func expandMacros(in string: String) -> String
    {
        // FIXME: Assumes first stringPart does not start with hotchar
        var badInsertKeys: [String] = []
        let stringParts = string.components(separatedBy: hotChar)
        var newParts = [stringParts.first!]
        for stringPart in stringParts.dropFirst() {
            guard let prefix = showMacro.getPrefixOf(stringPart) else {
                newParts.append(hotChar + stringPart)
                continue
            }
            if let indexOfClosingBracket = stringPart.firstIndex(of: "}") {
                let nameStart = stringPart.index(stringPart.startIndex, offsetBy: 2)
                let name = String(stringPart[nameStart..<indexOfClosingBracket])
                // suffix, e.g., in "$E{name}s" "s" is the suffix - not common
                var suffix = ""
                var s = stringPart.index(after: indexOfClosingBracket)
                while s < stringPart.endIndex, stringPart[s].isASCII && !stringPart[s].isWhitespace {
                    suffix.append(stringPart[s])
                    s = stringPart.index(after: s)
                }
                var maybeInsert: String? = nil
                if prefix == ShowMacro.callNamesMacro {
                    // unformatted call names
                    let name = programNameFor(callNames)
                    maybeInsert = "\n.No \(name)"
                }
                else if prefix == ShowMacro.formattedCallNamesMacro {
                    // formatted call name
                    let name = programNameFor(callNames)
                    maybeInsert = "\n.Nm \(name)"
                }
                else if let parameter = parameterWithName[name] {
                    maybeInsert = showMacro.getInsertAndFormattingSwitchFor(parameter, and: prefix)
                }
                guard var insert = maybeInsert else {
                    badInsertKeys.append("\(prefix)\(name)}")
                    continue
                }
                let tail = stringPart[s..<stringPart.endIndex]
                if prefix == ShowMacro.typeElementDescriptionMacro {
                    insert += suffix
                }
                // Return to normal font - only works if line started with a macro
                else if suffix.isEmpty {
                    // Return to normal font
                    insert.append(" No ")
                }
                else {
                    // Return to normal font with no space
                    insert.append(" Ns \(suffix)")
                }
                newParts.append(insert + tail)
            }
        }
        var expandedString = newParts.joined()
        if let first = expandedString.first, first.isNewline {
            expandedString.removeFirst()
        }
        if !badInsertKeys.isEmpty {
            let messages = badInsertKeys.map { "  Invalid parameter name or inappropriate show macro: $\($0)." }
            fatalUseOfAPI(messages, file: #file, line: #line)
        }
        return expandedString
    }
}

public extension ShowMacro {

    func getInsertAndFormattingSwitchFor(_ parameter: Parameter, and prefix: String) -> String?
    {
        var insert: String? = nil
        switch prefix {
        case Self.shortestLabelMacro:
            if let label = parameter.shortestLabel {
                insert = "\n.Fl \(label.dropFirst())"
            }
        case Self.longestLabelMacro:
            if let label = parameter.longestLabel {
                insert = "\n.Fl \(label.dropFirst())"
            }
        case Self .joinedLabelsMacro:
            let label = parameter.joinedLabels
            if !label.isEmpty {
                insert = "\n.Fl \(label.dropFirst())"
            }
            else {
                insert = ""
            }
        case Self.formattedTypeNameMacro:
            var typeName = mdocTypeNameOf(parameter)
            if parameter.isVariadic {
                typeName.append(" Ns ...")
            }
            insert = "\n.Ar \(typeName)"
        case Self.formattedTypeElementNameMacro:
            insert = "\n.Ar \(mdocTypeNameOf(parameter))"
        case Self.typeElementDescriptionMacro:
            insert = mdocTypeNameOf(parameter)
        default:
            insert = nil
        }
        return insert
    }
}
