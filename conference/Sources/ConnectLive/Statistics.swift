//
//  Statistics.swift
//  conference
//

import Foundation
import ConnectLiveSDK

struct StatisticsData: Hashable {
    var id: Int
    var direction: SessionDirection
    var type: StreamMediaType
    var name: String
    var profile: String
    var log: String
}

class Statistics: ObservableObject {
    @Published var report: [StatisticsData] = []

    @MainActor
    func update(local: LocalQualityStat?, remote: RemoteQualityStat?) {
        var newData: [StatisticsData] = []

        if let local = local {
            for metric in local.audioMetrics {
                var log: [String] = []
                log.append("stream:\(metric.streamId )")
                log.append("bytesSent:\(metric.bytesSent)")
                log.append("packetsSent:\(metric.packetsSent)")
                let data = StatisticsData(id: metric.streamId,direction: .up, type: .audio, name: "SEND_A", profile: "", log: log.joined(separator: "\n"))
                newData.append(data)
            }
            
            for metric in local.videoMetrics {
                var log: [String] = []
                log.append("stream:\(metric.streamId)")
                log.append("profile:\(metric.profile)")
                log.append("bytesSent:\(metric.bytesSent)")
                log.append("packetsSent:\(metric.packetsSent)")
                log.append("framesSent:\(metric.framesSent)")
                log.append("framesEncoded:\(metric.framesEncoded)")
                log.append("width:\(metric.frameWidth)")
                log.append("height:\(metric.frameHeight)")
                log.append("fps:\(metric.framesPerSecond)")
            
                let data = StatisticsData(id: metric.streamId,direction: .up, type: .video, name: "SEND_V", profile: metric.profile,log: log.joined(separator: "\n"))
                newData.append(data)
                
            }
        }


        if let remote = remote {
            remote.audioMetrics.forEach { metric in
                if metric.streamId == 0 {
                    return
                }
                
                var log: [String] = []
                log.append("participant:\(metric.participantId)")
                log.append("stream:\(metric.streamId)")
                log.append("receiver:\(metric.receiverId)")
                log.append("packetLost:\(metric.packetsLost)")
                log.append("bytesReceived:\(metric.bytesReceived)")
                log.append("samplesReceived:\(metric.totalSamplesReceived)")
                let data = StatisticsData(id: metric.streamId, direction: .down, type: .audio, name: "RECV_A", profile: "", log: log.joined(separator: "\n"))
                newData.append(data)
            }
            
            remote.videoMetrics.forEach { metric in
                if metric.streamId == 0 {
                    return
                }
                
                var log: [String] = []
                log.append("participant:\(metric.participantId)")
                log.append("receiver:\(metric.receiverId)")
                log.append("stream:\(metric.streamId)")
                log.append("packetLost:\(metric.packetsLost)")
                log.append("bytesReceived:\(metric.bytesReceived)")
                log.append("framesReceived:\(metric.framesReceived)")
                log.append("framesDecoded:\(metric.framesDecoded)")
                log.append("width:\(metric.frameWidth)")
                log.append("height:\(metric.frameHeight)")
                log.append("fps:\(metric.framesPerSecond)")
                
                let data = StatisticsData(id: metric.streamId, direction: .down, type: .video, name: "RECV_V", profile: "", log: log.joined(separator: "\n"))
                newData.append(data)
            }
        }

        if newData.isEmpty {
            return
        }
        
        newData.sort {
            if $0.direction != $1.direction {
                if $0.direction == .up {
                    return true
                } else {
                    return false
                }
            }

            if $0.type != $1.type {
                if $0.type == .video {
                    return true
                }
            }

            if !$0.profile.isEmpty && !$1.profile.isEmpty {
                if $0.profile == "m" && $1.profile == "h" {
                    return true
                }
                
                if $0.profile == "h" {
                    return false
                }
                
                if $0.profile == "l" {
                    return true
                }
            }
            return false
        }
        report = newData
    }
}
