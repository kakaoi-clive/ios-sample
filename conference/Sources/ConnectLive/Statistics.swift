//
//  Statistics.swift
//  conference
//

import Foundation
import ConnectLiveSDK

struct StatisticsData: Hashable {
    var id: Int
    var log: String
}

class Statistics: ObservableObject {
    @Published var report: [StatisticsData] = []
}
