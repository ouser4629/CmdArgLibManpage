//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

// Manual page meta-flag
public extension MetaFlag {

    /// A MetaFlag that prints a man page doucment to stdout
    init(manpageElements: [ShowElement]) {
        @Sendable
        func function(callNames: [String], values: [String], context: RunContext) -> Exception {
            let mdocSupport = Manpage(callNames: callNames, context: context, manpageElements: manpageElements)
            let page = mdocSupport.makeManpage()
            return Exception.stdout(page)
        }
        let newMetaFlag = MetaFlag(
            metaTypeFunction: function, isHelpMetaType: false, isManpageMetaType: true,
            isCompletionMetaType: false, showElements: manpageElements)
        self = newMetaFlag
    }
}
