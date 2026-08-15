//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

/// Functions that supposrt the default man page renderer
struct Manpage {
    let callNames: [String]
    let context: RunContext
    let manpageElements: [ShowElement]

    init( callNames: [String], context: RunContext, manpageElements: [ShowElement])
    {
        self.callNames = callNames
        self.context = context
        self.manpageElements = manpageElements
    }
}

extension Manpage {

    func makeManpage() -> String
    {
        var lines: [String] = []

        // Prologue
        if manpageElements.count < 1 {
            fatalUseOfAPI("missing manpage prologue show element", file: #file, line: #line)
        }
        guard case .linesBlock(let linesBlock) = manpageElements[0].member, linesBlock.header == "__PROLOGUE__" else {
            fatalUseOfAPI("the first man page show element must be a prologue", file: #file, line: #line)
        }
        let programName = programNameFor(callNames)
        let prologue = makePrologueAndNameSections(programName: programName, lines: linesBlock.lines)
        lines.append(prologue)
        if manpageElements.count < 2 {
            fatalUseOfAPI("Missing manpage synopsis show element", file: #file, line: #line)
        }
        var synopsis: [String] = []
        switch manpageElements[1].member {
        case .synopsisDef(_, let synopsisLines):
            synopsis = makeSynopsisSection(for: synopsisLines)
        default:
            fatalUseOfAPI("the second man page show element must be a synopsis", file: #file, line: #line)
        }
        lines += synopsis

        var badParameterNames: [String] = []
        let expander = ManpageExpander(callNames: callNames, context: context)
        var ndx = 2
        while ndx < manpageElements.count {
            let element = manpageElements[ndx]
            switch element.member {
            case .parameterElement:
                // Make a list of .parameterElements, ending with first other case, then
                // render as a block
                var parameterElements: [ParameterShowElement] = []
                while ndx < manpageElements.count {
                    let element = manpageElements[ndx]
                    guard case .parameterElement(let parameterElement) = element.member else {
                        break
                    }
                    parameterElements.append(parameterElement)
                    ndx += 1
                }
                if !parameterElements.isEmpty {
                    let (parameterLines, badNames) = makeParameterLines(from: parameterElements)
                    lines += parameterLines
                    badParameterNames.append(contentsOf: badNames)
                }
            case .commandContextElement:
                var commandContexts: [CommandContext] = []
                while ndx < manpageElements.count {
                    let element = manpageElements[ndx]
                    if case .commandContextElement(let context) = element.member {
                        commandContexts.append(context)
                        ndx += 1
                    }
                    else {
                        break
                    }
                }
                lines.append(".Bl -tag -width indent")
                for context in commandContexts {
                    lines.append(".It Sy \(context.name)")
                    lines.append(context.synopsis)
                }
                lines.append(".El")
            case .textBlock(let textBlock):
                if var tbHead = textBlock.header {
                    tbHead = tbHead.trimmingCharacters(in: .whitespacesAndNewlines)
                    if tbHead.isEmpty {
                        lines.append(".Pp")
                    } else {
                        lines.append(".Sh \(tbHead)")
                    }
                }
                let tbLines = textBlock.lines
                let interpolatedLines = tbLines.map { expander.expandMacros(in: $0) }.filter { !$0.isEmpty }
                if !interpolatedLines.isEmpty {
                    lines += interpolatedLines
                }
                ndx += 1
            case .linesBlock(let linesBlock):
                if var tbHead = linesBlock.header {
                    tbHead = tbHead.trimmingCharacters(in: .whitespacesAndNewlines)
                    if tbHead.isEmpty {
                        lines.append(".Pp")
                    } else {
                        lines.append(".Sh \(tbHead)")
                    }
                }
                let tbLines = linesBlock.lines
                let interpolatedLines = tbLines.map { expander.expandMacros(in: $0) }.filter { !$0.isEmpty }
                if !interpolatedLines.isEmpty {
                    lines += interpolatedLines
                }
                ndx += 1
            default:
                ndx += 1
            }
            if !badParameterNames.isEmpty {
                let errors = badParameterNames.map {"unrecognized name in manpage show element: \"\($0)\"" }
                fatalUseOfAPI(errors, file: #file, line: #line)
            }
        }
        return lines.joined(separator: "\n")
    }
}

extension Manpage {

    /// lines are description, date, operatingSystem
    func makePrologueAndNameSections(programName: String, lines: [String]) -> String
    {
        let description = lines[0].trimmingCharacters(in: .whitespaces)
        var dateString = lines[1]
        if dateString.isEmpty {
            dateString = Date().formatted(
                .dateTime.month(.wide).day(.defaultDigits).year().locale(Locale(identifier: "en_US")))
        }
        let commands = """
            .Dd \(dateString)
            .Dt \(programName.uppercased()) 1
            .Os \(lines[2])
            .Sh NAME
            .Nm \(programName)
            .Nd \(description)
            """
        return commands
    }
}

extension Manpage {

    func makeParameterLines(from parameterElements: [ParameterShowElement]) -> (lines: [String], badNames: [String])
    {
        let expander = ManpageExpander(callNames: callNames, context: context)
        var lines = [".Bl -tag -width indent"]
        var badParameterNames: [String] = []
        for parameterElement in parameterElements {
            if parameterElement.isPseudo {
                lines.append(".It Sy \(parameterElement.name)")
                let description = parameterElement.description
                let descriptionLines = description.components(separatedBy: .newlines)
                let interpolatedDescriptions = descriptionLines.map { expander.expandMacros(in: $0) }
                lines += interpolatedDescriptions
            }
            else {
                guard let parameter = context.parameterNamed[parameterElement.name] else {
                    badParameterNames.append(parameterElement.name)
                    continue
                }
                if parameterElement.description.isEmpty {
                    continue
                }
                let paramaterSyntax = parameterOptionLineSynopsisFor(parameter, separator: ", ")
                lines.append(paramaterSyntax)
                var tail = "."
                if !parameter.isFlagOrMetaFlag && !parameter.isMeta {
                    if let defaultValue = parameter.defaultValue, defaultValue != "\"[]\"" && defaultValue != "[]" {
                        tail = " (default: \(defaultValue))."
                    }
                }
                let description = parameterElement.description + tail
                let descriptionLines = description.components(separatedBy: .newlines)
                let interpolatedDescriptions = descriptionLines.map { expander.expandMacros(in: $0) }
                lines += interpolatedDescriptions
            }
        }
        lines.append(".El")
        return (lines, badParameterNames)
    }
}

extension Manpage {

    /// Make a mulitline synopsis section
    /// - Parameters:
    ///   - specsTrailerArray: An array of ([Spec], Trailer)
    /// - Returns: The synopsis lines in mdoc format
    ///
    /// Each spec is <label>:<type>[=]. If "=" is specified the dummy will have a default value. The label an type follow the usual rules
    func makeSynopsisSection(for synopsisLines: [SynopsisLine] = []) -> [String]
    {
        var errorMessages: [String] = []
        var lines = [".Sh SYNOPSIS"]
        for rawLine in synopsisLines {
            let lineParameters = synopsisLineParameters(in: rawLine, for: context, errorMessages: &errorMessages)
            let (shortFlagsChunk, remainingParameters) = getPackedShortFlagChunk(for: lineParameters)
            lines.append(".Nm " + callNames.joined(separator: " "))
            if let shortFlagsChunk {
                lines.append(shortFlagsChunk)
            }
            for parameter in remainingParameters {
                let chunks = makeSynopisChunks(for: parameter)
                lines += chunks
            }
        }
        if !errorMessages.isEmpty {
            fatalUseOfAPI(errorMessages, file: #file, line: #line)
        }
        return lines
    }

    /// Flags with short names collected spearately
    private func makeSynopisChunks(for parameter: Parameter) -> [String]
    {
        var parameterIsRequired = parameter.isRequired
        if parameter.isDummySynopsisParameter {
            parameterIsRequired = parameter.defaultValue != nil
        }
        let shortestLabel = parameter.shortLabel ?? parameter.oldStyleLabel ?? parameter.longLabel ?? ""
        let labelName = shortestLabel.dropFirst()
        let typeName = mdocTypeNameOf(parameter)
        if typeName.isEmpty {
            let chunk = parameterIsRequired ? ".Fl \(labelName)" : ".Op Fl \(labelName)"
            return [chunk]
        }
        let chunkString: String
        if parameterIsRequired {
            let labelPart = labelName.isEmpty ? "." : ".Fl \(labelName) "
            if parameter.isVariadic {
                chunkString = "\(labelPart)Ar \(typeName) Ns ..."
            } else {
                chunkString = "\(labelPart)Ar \(typeName)"
            }
        } else {
            let labelPart = labelName.isEmpty ? "" : " Fl \(labelName)"
            if parameter.isArray {
                chunkString = ".Eo \\&[ \(labelPart) Ar \(typeName) Ec ]"
            } else if parameter.isVariadic {
                chunkString = ".Eo \\&[ \(labelPart) Ar \(typeName) Ns ... Ec ]"
            } else {
                chunkString = ".Eo \\&[ \(labelPart) Ar \(typeName) Ec ]"
            }
        }
        return [chunkString]
    }

    fileprivate func prefix(_ string: String?, with prefix: String = "-") -> String?
    {
        string == nil ? nil : "\(prefix)\(string!)"
    }

    func parameterOptionLineSynopsisFor(_ parameter: Parameter, separator: String) -> String
    {
        let labelNames = [parameter.shortLabelName, parameter.oldStyleLabelName, prefix(parameter.longLabelName)]
        let labelPart = ".It " + labelNames.compactMap { prefix($0, with: "Fl ") }.joined(separator: separator)
        if parameter.isFlagOrMetaFlag {
            return labelPart
        }
        var typeName = mdocTypeNameOf(parameter)
        if parameter.isVariadic {
            typeName.append(" Ns ...")
        }
        return labelPart + " Ar \(typeName)"
    }
}
