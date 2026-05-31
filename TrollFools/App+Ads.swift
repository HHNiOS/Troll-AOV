//
//  App+Ads.swift
//  TrollFools
//
//  Created by Rachel on 9/9/2025.
//

import Foundation

extension App {
    static let advertisementApp: App = {
        [
            App(
                bid: NSLocalizedString("", comment: ""),
                name: NSLocalizedString("CheatStore Mini App", comment: ""),
                type: "System",
                teamID: "GXZ23M5TP2",
                url: URL(string: "https://t.me/cheatstores_bot")!,
                alternateIcon: .init(named: "tricon-default"),
                isAdvertisement: true
            ),
        ].randomElement()!
    }()
}
