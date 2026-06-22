//
//  InjectorV3+Backup.swift
//  TrollFools
//
//  Created by 82Flex on 2025/1/10.
//

import Foundation

extension InjectorV3 {
    // MARK: - Constants

    static let alternateSuffix = "troll-fools.bak"

    static func alternateURL(for target: URL) -> URL {
        target.appendingPathExtension(Self.alternateSuffix)
    }

    // MARK: - Shared Methods

    func hasAlternate(_ target: URL) -> Bool {
        let alternateURL = Self.alternateURL(for: target)
        return FileManager.default.fileExists(atPath: alternateURL.path)
    }

    func makeAlternate(_ target: URL) throws {
        guard !hasAlternate(target) else { return }
        let alternateURL = Self.alternateURL(for: target)
    
        try cmdCopy(from: target, to: alternateURL, clone: true, overwrite: true)
    }

    func removeAlternate(_ target: URL) throws {
        guard hasAlternate(target) else {
            return
        }
        let alternateURL = Self.alternateURL(for: target)
        try cmdRemove(alternateURL)
    }

    func restoreAlternate(_ target: URL) throws {
        guard hasAlternate(target) else { return }
        let alternateURL = Self.alternateURL(for: target)
    
        try cmdCopy(from: alternateURL, to: target, clone: true, overwrite: true)
    
        try cmdChangeOwnerToInstalld(target, recursively: true)
    }
}
