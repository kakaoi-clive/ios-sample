//
//  RoomError.swift
//  conference
//

import Foundation

struct RoomError: Identifiable {
    var id: Int {
        return code
    }

    let code: Int
    let message: String
    let isCritical: Bool
}
