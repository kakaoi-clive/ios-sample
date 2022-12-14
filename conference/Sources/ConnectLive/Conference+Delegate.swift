//
//  Conference+.swift
//  conference
//

import Foundation
import Combine
import ConnectLiveSDK

/// 룸 이벤트 delegate
///
/// RemoteParticipant 타입의 경우 class 이므로, 별도 저장시 레퍼런스 카운터 관리가 필요합니다.
/// 콜백으로 전달되는 객체의 별도 저장은 권장하지 않으며, 필요시 room.participants 로 참여자 객체를
/// 얻어올 수 있습니다.
extension Conference: RoomDelegate {

    /// 룸 접속 진행상태
    func onConnecting(progress: Float) {
        print("[onConnecting] progress:\(progress)")
        status = .connecting

        // 진행상태 표시가 필요한 경우 관련 처리
    }


    /// 룸 접속 완료
    func onConnected(participantIds: [String]) {
        print("[onConnected] onConnected:\(participantIds)")
        guard let room = self.room else { return }
        status = .connected

        // 참여중인 사용자 처리
        print("[onConnected] 내 ID:\(room.localParticipant.id)")

        // 자신을 포함한 참여자id 목록
        // 이 샘플에서는 별도의 참여자 정보를 제공하지 않으므로, sdk의 참여자 id를 단순하게 사용합니다.
        // 일반적으로 서비스에서는 별도의 내부 시스템을 통해 회원 정보를 연계해 참여자 데이터를 구성합니다.
        // 이 경우 서비스내 참여자와 sdk의 참여자를 매칭시키는 별도의 테이블을 구성해야 합니다.
        self.participantIds = participantIds.sorted(by: <)
        for id in participantIds {
            let user = ServiceParticipant(id: id)
            if id == room.localParticipant.id {
                if !room.localParticipant.videos.isEmpty {
                    user.video = true
                }

                if !room.localParticipant.audios.isEmpty {
                    user.audio = true
                }
            } else {
                if let participant = room.remoteParticipants[id] {
                    if !participant.audios.isEmpty {
                        user.audio = true
                    }

                    user.video = false
                    user.screen = false
                    for video in participant.videos.values {
                        user.videos.append(video.id)

                        // 각 플랫폼 샘플마다 기본으로 설정된 extraValue 값이 다를 수 있으므로 플랫폼 샘플간 연동 시 확인 필요
                        // web 샘플의 경우 extraValue = "camera", "screen" 사용
                        if video.extraValue != "screen"{
                            user.video = true
                        } else {
                            user.screen = true
                        }
                    }
                }
            }
            participants[id] = user
        }

        // 비디오 구독 및 렌더러 설정
        updateVideoSubscription()
    }


    /// 룸 접속 해제
    func onDisconnected(reason: DisconnectReason) {
        print("[onDisconnected] reason:\(reason)")
        if let error = latestRoomError {
            if error.isCritical {
                // 에러로 인한 종료 처리

            }
        }

        participants.removeAll()
        currentParticipantVideos.removeAll()
        status = .disconnected
        room = nil
        media = nil
    }


    /// 에러
    func onError(code: Int, message: String, isCritical: Bool) {
        print("[onError] code:\(code), message:\(message), isCritical:\(isCritical)")

        // 중요 에러인 경우 onDisconnected가 호출되므로, 에러에 대한 ui 처리를 위해 저장
        latestRoomError = RoomError(code: code, message: message, isCritical: isCritical)
        errorMessage = latestRoomError?.message ?? ""
    }


    /// 참여자 입장
    func onParticipantEntered(remoteParticipant: RemoteParticipant) {
        print("[onParticipantEntered] 😀(\(remoteParticipant.id)):참여")

        // 서비스 참여자 목록을 업데이트합니다.
        // id 목록은 정렬되어 있으므로 정렬된 위치에 삽입
        let id = remoteParticipant.id
        var slice = participantIds[...]
        while !slice.isEmpty {
            let middle = slice.index(slice.startIndex, offsetBy: slice.count / 2)
            if id < slice[middle] {
                slice = slice[..<middle]
            } else {
                slice = slice[slice.index(after: middle)...]
            }
        }
        participantIds.insert(id, at: slice.startIndex)
        participants[id] = ServiceParticipant(id: id)
    }


    /// 참여자 퇴장
    ///
    /// 정상적으로 퇴장 처리 없이 퇴장한 사용자의 경우 퇴장 이벤트가 늦게 전달될 수 있습니다.
    /// 이 경우 퇴장한 사용자의 정보가 일정시간 표시될 수 있으므로,
    /// 서비스에서 사용하는 별도 시스템을 통해 퇴장 여부를 체크해 UI에 반영해야 합니다.
    func onParticipantLeft(remoteParticipant: RemoteParticipant) {
        print("[onParticipantLeft] 😀(\(remoteParticipant.id)):퇴장")

        // 서비스 참여자 목록에서 제거
        if let index = participantIds.firstIndex(where: { $0 == remoteParticipant.id } ) {
            participantIds.remove(at: index)
        }

        participants.removeValue(forKey: remoteParticipant.id)
        updateVideoSubscription()
    }

    /// 로컬 미디어 송출 시작
    func onLocalMediaPublished(localMedia: LocalMedia?) {
        print("[onLocalMediaPublished] 😀로컬 미디어 송출 시작")
        guard let media = localMedia else { return }
        if let user = participants[myId] {
            user.video = media.video.active
            user.audio = media.audio.active
        }
    }


    /// 로컬 미디어 송출 중단
    func onLocalMediaUnpublished(localMedia: LocalMedia?) {
        print("[onLocalMediaUnpublished] 😀로컬 미디어 송출 중단")
        if let user = participants[myId] {
            user.video = false
            user.audio = false
        }
    }


    /// 원격 참여자 비디오 송출 시작
    func onRemoteVideoPublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo) {
        print("[onRemoteVideoPublished] 😀(\(remoteParticipant.id)):비디오 스트림 송출 시작")

        if let user = participants[remoteParticipant.id] {
            user.videos.append(remoteVideo.id)

            if remoteVideo.extraValue != "screen" {
                user.video = true
            } else {
                user.screen = true
            }
        }
        // 비디오 구독 및 렌더러 설정
        updateVideoSubscription()
    }


    /// 원격 참여자 비디오 송출 중단
    /// 원격 참여자의 비디오가 해제되면 sdk 에서 unsubscribe가 자동으로 수행됩니다.
    func onRemoteVideoUnpublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo) {
        print("[onRemoteVideoUnpublished] 😀(\(remoteParticipant.id)):비디오 스트림 해제")

        if let user = participants[remoteParticipant.id] {
            if let index = user.videos.firstIndex(where: { $0 == remoteVideo.id }) {
                user.videos.remove(at: index)
            }

            if remoteVideo.extraValue != "screen" {
                user.video = false
            } else {
                user.screen = false
            }
        }
        // 비디오 구독 및 렌더러 설정
        updateVideoSubscription()
    }


    /// 원격 참여자 오디오 송출 시작
    func onRemoteAudioPublished(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio) {
        print("[onRemoteAudioPublished] 😀(\(remoteParticipant.id)):오디오 스트림 송출 시작")

        if let item = participants[remoteParticipant.id] {
            item.audio = true
        }
    }


    /// 원격 참여자 오디오 송출 중단
    func onRemoteAudioUnpublished(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio) {
        print("[onRemoteAudioUnpublished] 😀(\(remoteParticipant.id)):오디오 스트림 해제")
        if let item = participants[remoteParticipant.id] {
            item.audio = false
        }
    }


    /// 원격 참여자 오디오 구독(발화 이벤트)
    ///
    /// 서비스에서는 이 이벤트를 통해 발화 관련 UI 업데이트, 사용자 화면 표시 등을 추가 할 수 있습니다.
    /// 이 이벤트는 마이크 입력에 민감하게 반응 하므로, 매우 빠른 간격으로 발생할 수 있습니다.
    /// 카운팅이나 상태 처리 등 별도의 threshold 루틴을 통해 ui 업데이트를 진행해야 합니다.
    func onRemoteAudioSubscribed(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio) {
        print("[onRemoteAudioSubscribed] 😀(\(remoteParticipant.id)):오디오 구독")
        if let item = participants[remoteParticipant.id] {
            item.speaking = true
        }
    }

    /// 원격 참여자 오디오 구독 해제(발화 해제 이벤트)
    ///
    /// 이 이벤트는 매우 빠른 간격으로 발생할 수 있으므로, 카운팅이나 상태처리 등 별도의 threshold 루틴을 통해 ui 업데이트를 진행해야 합니다.
    func onRemoteAudioUnsubscribed(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio) {
        print("[onRemoteAudioUnsubscribed] 😀(\(remoteParticipant.id)):오디오 구독해제")
        if let item = participants[remoteParticipant.id] {
            item.speaking = false
        }
    }


    /// 원격 참여자의 비디오 상태 변경 이벤트
    func onRemoteVideoStateChanged(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo) {
        print("[onRemoteVideoStateChanged]")

        if let item = participants[remoteParticipant.id] {
            if remoteVideo.extraValue != "screen" {
                item.video = remoteVideo.active
            } else {
                item.screen = remoteVideo.active
            }

        }
    }


    /// 원격 참여자의 오디오 상태 변경 이벤트
    func onRemoteAudioStateChanged(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio) {
        print("[onRemoteVideoStateChanged]")

        if let item = participants[remoteParticipant.id] {
            item.audio = remoteAudio.active
        }
    }


    /// 메시지
    func onUserMessage(senderId: String, message: String, type: String) {
        print("[onMessage]")
        receivedMessage = "[\(senderId)] \(message)"
    }
}
