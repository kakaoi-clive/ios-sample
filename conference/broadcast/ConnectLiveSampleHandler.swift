//
//  SampleHandler.swift
//  broadcast-extension
//

import ReplayKit
import Combine
import ConnectLiveSDK
import os.log

/// 로컬 화면공유 익스텐션
///
/// 익스텐션이 동작하기 위해서 아래의 설정들이 정상적으로 이루어져야 합니다.
///
/// 메인앱의 백그라운드 모드 활성화 : target - capabilities - Background Modes - Voice over IP
/// 화면공유 picker에서 표시할 display name 설정 : target - general - display name (일반적으로 메인앱 이름과 동일하게 변경)
/// RPBroadcastSampleHandler 이름 설정 : target - info - NSExtension - NSExtensionPrincipalClass(기본값 SampleHandler가 아닌 경우)
/// 앱 그룹 관련 설정
class ConnectLiveSampleHandler: RPBroadcastSampleHandler {
    // 앱 그룹
    let appGroupName = "group.ai.kakaoi.connectlive.conferencesample"
    var screenShare: ScreenShare?
    var disconnectSemaphore: DispatchSemaphore?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        print("[ConnectLiveSampleHandler.broadcastStarted] group:\(appGroupName)")

        do {
            screenShare = try ConnectLive.createScreenShare(appGroup: appGroupName)
        } catch {
            finishBroadcastWithError(error)
        }

        disconnectSemaphore = DispatchSemaphore(value: 0)
        screenShare?.start() { [weak self] error, msg in
            guard let self = self else { return }

            // 오류에 따라 메시지 처리
            var key = "default"

            switch error {
            case .invalidData:
                key = "invalidData"

            case .stopBroadcast:
                key = "stopBroadcast"

            case .meetingFinished:
                key = "meetingFinished"

            case .broadcastFailed:
                key = "broadcastFailed"

            case .broadcastClosed:
                key = "broadcastClosed"

            @unknown default:
                break
            }

            // 익스텐션이 종료되는 경우 처리
            let message =  NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.main, value: "", comment: "").appending(msg)
            let userInfo = [NSLocalizedFailureReasonErrorKey: message]
            let error = NSError(domain: "ai.kakaoi.connectlive.conferencesample", code: -1, userInfo: userInfo)
            self.finishBroadcastWithError(error)
        }
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        print("[ConnectLiveSampleHandler.broadcastPaused]")
        screenShare?.pause()
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        print("[ConnectLiveSampleHandler.broadcastResumed]")
        screenShare?.resume()
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        print("[ConnectLiveSampleHandler.broadcastFinished]")
        screenShare?.stop { [weak self] in
            print("[ConnectLiveSampleHandler.braodcastFinished] completed")
            self?.disconnectSemaphore?.signal()
        }

        disconnectSemaphore?.wait()
        screenShare = nil

        print("[ConnectLiveSampleHandler.broadcastFinished] finished")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            screenShare?.sendVideoFrame(sampleBuffer: sampleBuffer)

        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}

