//  Copyright (c) 2025-2026 Psummerland2 LLC.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CmdArgLibManpage",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CmdArgLibManpage", targets: ["CmdArgLibManpage"])
    ],
    dependencies: [
        .package(url: "https://github.com/ouser4629/CmdArgLibCore.git", branch: "main")
    ],
    targets: [
        .target(
            name: "CmdArgLibManpage",
            dependencies: ["CmdArgLibCore"]
        )
    ]
)
