//
//  GitService.swift
//  pydeApp
//
//  Created by Huima on 2023/11/12.
//

import Foundation
import SwiftGit2


extension LocalGitServiceProvider {
    
    func history() async throws -> CommitIterator {
        do {
            let repository =  try self.checkedRepository()
            let currentBranch = try await self.head() as! Branch
            return repository.commits(in: currentBranch)
        } catch {
            throw error
        }
    }
}


extension Commit: Identifiable {
    public var id: Int {
        return self.hashValue
    }
    
    
}
