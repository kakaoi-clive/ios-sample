//
//  Statistics.swift
//  conference
//

import Foundation
import ConnectLiveSDK

struct StatisticsData: Identifiable {
    var id: Int
    var direction: SessionDirection
    var type: StreamMediaType
    var name: String
    var log: String
}

class Statistics: ObservableObject {
    @Published var report: [StatisticsData] = []

    @MainActor
    func update(local: QualitySession?, remote: QualitySession?) {
        var newData: [StatisticsData] = []

        if let local = local {
            for metric in local.metrics {
                var log: [String] = []

                let bytesSent = metric.bytesSent ?? 0
                let packetsSent = metric.packetsSent ?? 0

                log.append("stream:\(metric.streamId )")

                switch metric.type {
                case .audio:
                    log.append("bytesSent:\(bytesSent)")
                    log.append("packetsSent:\(packetsSent)")

                case .video:
                    log.append("profile:\(metric.profile ?? .empty)")
                    log.append("bytesSent:\(bytesSent)")
                    log.append("framesSent:\(metric.framesSent ?? 0)")
                    log.append("framesEncoded:\(metric.framesEncoded ?? 0)")

                @unknown default:
                    break
                }

                let data = StatisticsData(id: metric.streamId,direction: .up, type: metric.type, name: "SEND_\(metric.type.rawValue)", log: log.joined(separator: "\n"))
                newData.append(data)
            }
        }


        if let remote = remote {
            remote.metrics.forEach { metric in
                if metric.streamId == 0 {
                    return
                }

                var log: [String] = []

                let receiverId = metric.receiverId ?? 0
                let bytesReceived = metric.bytesReceived ?? 0

                log.append("receiver:\(receiverId)")
                log.append("stream:\(metric.streamId)")
                log.append("packetLost:\(metric.packetsLost ?? 0)")

                switch metric.type {
                case .audio:
                    log.append("bytesReceived:\(bytesReceived)")
                    log.append("samplesReceived:\(metric.totalSamplesReceived ?? 0)")

                case .video:
                    log.append("bytesReceived:\(bytesReceived)")
                    log.append("framesReceived:\(metric.framesReceived ?? 0)")
                    log.append("framesDecoded:\(metric.framesDecoded ?? 0)")

                @unknown default:
                    break
                }

                let data = StatisticsData(id: metric.streamId, direction: .down, type: metric.type, name: "RECV_\(metric.type.rawValue)", log: log.joined(separator: "\n"))
                newData.append(data)
            }
        }

        newData.sort {
            if $0.direction != $1.direction {
                if $0.direction == .up {
                    return true
                } else {
                    return false
                }
            }

            if $0.type == .video {
                return true
            }

            return false
        }
        report = newData
    }
}
