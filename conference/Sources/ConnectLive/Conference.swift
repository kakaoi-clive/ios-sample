//
//  Conference.swift
//  conference
//

import AVFoundation
import Combine
import ConnectLiveSDK



/// ConnectLive SDK의 대부분의 기능이 포함된 예시 클래스입니다.
///
///
class Conference: ObservableObject {
    // ConnectLive sdk 관련 객체
    var config = Config()
    var room: Room?
    var media: LocalMedia?

    var cancelBag = Set<AnyCancellable>()

    // 서비스 UI 처리를 위한 프로퍼티
    @Published var status: RoomStatus = .initialized
    @Published var video: Bool = true
    @Published var audio: Bool = true
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var errorMessage: String = ""
    
    // 로컬 화면 공유 상태 전달용 프로퍼티
    @Published var screenShareStatus: ScreenShareData.ExtensionStatus = .notAvailable

    @Published var receivedMessage: String = ""

    
    // 전체 참여자 정보
    var participants: [String: ServiceParticipant] = [:]

    // 전체 참여자id 목록 : 참여자 id 정렬 용도로 사용
    var participantIds: [String] = []

    // 현재 화면에 표시될 참여자 비디오, 정렬된 참여자 중에 화면에 표시할 참여자 선택을 위해 사용
    var currentParticipantVideos: [ParticipantVideoItem] = []

    // 룸 에러 저장 : 종료시 에러 여부 확인용
    var latestRoomError: RoomError?

    let statistics: Statistics = Statistics()

    var levelTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var statTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // 서비스에서 화면공유를 지원하는 경우 관련 값
    // 화면공유는 iOS 브로드캐스트 익스텐션을 사용하므로 앱그룹과 익스텐션의 번들id가 설정되어야 합니다.
    let appGroup: String = "group.ai.kakaoi.connectlive.conferencesample"
    let extensionBundleId: String = "ai.kakaoi.connectlive.conferencesample.broadcast"

    var version: String {
        ConnectLive.version
    }

    var myId: String {
        room?.localParticipant.id ?? ""
    }

    init() {
        // AudioSession 설정
        // ios의 경우 앱에서 마이크를 사용하기 위해 카테고리, 모드 설정이 이루어져야 합니다.
        // 백그라운드, 화면공유에서 오디오가 정상 동작하려면 옵션에 mixWithOthers or duckOthers 가 설정되어야 합니다.
        ConnectLive.setAudioSessionConfiguration(category: .playAndRecord,
                                                 mode: .default,
                                                 options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth],
                                                 delegate: nil)

        // 미디어 관련 프로퍼티 바인딩
        bindLocalMedia()

        bindTimer()
    }


    // MARK: - 로컬 미디어 설정 및 연결

    /// 로컬 미디어 생성 및 시작
    ///
    /// 룸 입장 전 로컬 미디어를 설정합니다.
    func createLocalMedia() {
        if self.media != nil { return }

        // 로컬 미디어 설정

        // 비디오 트랙 유무
        config.mediaOptions.hasVideo = true

        // 오디오 트랙 유무
        config.mediaOptions.hasAudio = true

        // 비디오 트랙이 존재하는 경우 연결 시 비디오 활성화 여부
        // 로비와 같은 ui에서 비디오를 끄고 입장할때 사용합니다.
        config.mediaOptions.video = video

        // 오디오 트랙이 존재하는 경우 시작 시 오디오 활성화 여부
        // 로비와 같은 ui에서 오디오를 끄고 입장할때 사용합니다.
        config.mediaOptions.audio = audio

        // 비디오 소스
        config.mediaOptions.source = .camera

        // 카메라 위치
        config.mediaOptions.position = cameraPosition

        // 카메라 회전 방식
        config.mediaOptions.rotationType = .appOrientation

        // 시뮬레이터 카메라 대체 소스: 해당 파일이 프로젝트에 포함되어야 합니다.
        config.mediaOptions.fileName = "sample.mov"


        guard let media = ConnectLive.createLocalMedia(config: config) else {
            assertionFailure("카메라 캡처러 생성 실패")
            return
        }

        self.media = media

        Task {
            try await media.start()
        }
    }


    /// 룸 입장
    ///
    /// 지정된 roomId로 룸에 입장합니다.
    func connectRoom(roomId: String) {
        // 룸 객체 생성
        let room = ConnectLive.createRoom(config: config, delegate: self)

        // 룸 입장
        room.connect(roomId: roomId)

        // 로컬 미디어 게시
        // 원하는 시점에 호출할 수 있으며, 미리 호출한 경우 룸 입장 및 송출 세션 연결 이후에 게시됩니다.
        try? room.publish(media)

        self.room = room
    }


    /// 룸 퇴장
    ///
    /// 종료 처리 시 sdk의 객체를 별도 보관하고 있는 경우 해당 레퍼런스를 정리하고, room의 disconnect() 를 호출합니다.
    /// disconnect() 호출뒤 SDK 내부에서 종료 작업 완료 후 RoomDelegate.onDisconnected 콜백이 호출됩니다.
    /// onDisconnected에서 종료 완료를 확인하고, UI 종료 작업을 진행합니다.
    func leave() {
        if screenShareStatus == .broadcastStarted || screenShareStatus == .broadcastReady {
            stopScreensharing(isLeftRoom: true)
        }

        status = .disconnecting

        Task {
            await media?.stop()
            
            // room 에서 퇴장합니다.
            room?.disconnect()
        }
    }




    // MARK: - 비디오 관련

    /// 상대방의 비디오를 구독하는 예시입니다.
    ///
    /// 오디오의 경우 발화자에 따라 자동으로 구독, 해제가 이루어지므로 추가적인 처리없이 상대방의 소리를 수신하게 됩니다.
    /// 비디오의 경우에는 자동적으로 구독이 이루어지지 않으므로, 서비스별 화면 구성에 맞게 비디오 구독 여부를 결정해야 합니다.
    /// 구독을 통해 상대방의 비디오를 수신하기 위해서는 Room의 remoteParticipants에서 해당 참여자의 비디오 스트림id를 얻어
    /// 직접 구독 처리를 진행해야 합니다.
    ///
    /// 비디오 구독수가 늘어날수록 많은 데이터와 자원을 사용하게 되므로, 필요한 비디오만을 구독해야 합니다.
    func subscribe(participantId: String, videoId: Int) {
        print("[subscribe] 참여자 비디오 스트림 할당 요청, \(participantId)")
        guard let room = self.room else { return }
        guard let participant = room.remoteParticipants[participantId] else { return }
        guard let remoteVideo = participant.videos[videoId] else { return }

        // 비디오 구독 여부 확인
        if remoteVideo.isSubscribed {
            print("[subscribe] \(participantId)의 remoteVideo 이미 구독 중")
            return
        }


        // 비디오 구독
        Task {
            let result = await room.subscribe(videoId: remoteVideo.id)
            switch result {
            case .success():
                print("[subscribe] 구독 시작")

            case .failure(let error):
                if case let ConnectLiveError.error(code, message) = error {
                    print("[subscribe] 구독 오류, \(code), \(message)")
                } else {
                    print("[subscribe] 구독 오류, \(error.localizedDescription)")
                }
            }
        }
    }


    /// 상대방의 비디오 구독을 해제합니다.
    ///
    /// 구독중인 참여자의 비디오 스트림은 비디오 데이터를 수신합니다.
    /// 화면에 보이지 않거나 렌더러가 할당되지 않은 사용자는 구독을 해제해 데이터를 수신 받지 않게 합니다.
    func unsubscribe(participantId: String, videoId: Int) {
        print("[unsubscribe] 참여자 비디오 스트림 해제 요청, \(participantId)")
        guard let room = self.room else { return }
        guard let participant = room.remoteParticipants[participantId] else { return }
        guard let remoteVideo = participant.videos[videoId] else { return }

        // 비디오 구독 여부 확인
        if !remoteVideo.isSubscribed {
            print("[unsubscribe] \(participantId)의 remoteVideo 구독 중이 아닙니다")
            return
        }

        // 비디오 구독 해제
        Task {
            let result  = await room.unsubscribe(videoId: remoteVideo.id)
            switch result {

            case .success():
                print("[unsubscribe] 구독 해제")

            case .failure(let error):
                if case let ConnectLiveError.error(code, message) = error {
                    print("[unsubscribe] 구독 오류, \(code), \(message)")
                } else {
                    print("[unsubscribe] 구독 오류, \(error.localizedDescription)")
                }
            }
        }
    }


    /// 비디오 스트림에 렌더뷰(UIRenderView)를 첨부합니다.
    ///
    /// 구독중인 비디오 스트림에 렌더뷰를 첨부하면, 비디오 스트림으로 전달되는 데이터를 해당 뷰에 표시하게 됩니다.
    /// 만약 렌더뷰가 이미 다른 스트림이 첨부되어 있는 경우 기존 연결은 분리됩니다.
    func attach(participantId: String, videoId: Int, renderView: RenderView) {
        guard let room = self.room else { return }
        guard let participant = room.remoteParticipants[participantId] else { return }
        guard let remoteVideo = participant.videos[videoId] else { return }

        remoteVideo.attach(renderView.uiView)
    }



    /// 화면에 표시할 참여자 정보를 업데이트합니다.
    ///
    /// 실제 서비스에서는 각 사용자 정보와 연결상태, 발화여부 등 여러가지 정보를 통해 화면에 표시할 유저를 선택해야 합니다.
    /// 이 샘플에서는 단순하게 목록에서 n 명을 선택합니다.
    /// 목록을 업데이트하고 뷰가 화면을 배치하도록 이벤트를 전달합니다.
    func updateVideoSubscription() {
        print("[Conference.updateVideoSubscription]")
        var temp: [ParticipantVideoItem] = []
        for id in participantIds {
            if id == myId {
                continue
            }

            // id에 해당하는 sdk의 유저 확인
            // 각 참여자는 여러개의 비디오 스트림을 가질 수 있습니다.(ex: 카메라 and 화면공유)
            // 이 샘플에서는 참여자의 모든 비디오 스트림을 표시하므로, 각각의 비디오 항목을 생성합니다.
            if let participant = participants[id] {
                for vid in participant.videos {
                    temp.append(ParticipantVideoItem(pid: id, vid: vid))
                }
            } else {
                continue
            }


            if temp.count == Renderer.remoteViewCount {
                break
            }
        }
        print("[Conference.updateVideoSubscription] user:\(temp.count)")
        currentParticipantVideos = temp
        objectWillChange.send()
    }




    /// 비디오 프로파일을 변경하는 예시입니다.
    ///
    /// iOS의 경우 프로파일은 고정되어 있어 변경이 불가능하며, 타 플랫폼 참여자의 비디오 프로파일을 변경할 수 있습니다.
    func changeVideoProfile(participantId: String, profile: VideoProfileType) {
        guard let room = self.room else { return }
        if let participant = room.remoteParticipants[participantId] {
            if let remoteVideo = participant.videos.first(where: { $0.value.extraValue != "screen" })?.value {
                if remoteVideo.profile != .empty {
                    try? remoteVideo.setProfile(profile)
                }
            }
        }
    }


    /// 메시지를 전송하는 예시입니다.
    ///
    /// 대상의 id 목록과 메시지로 해당 대상에게 메시지를 전달할 수 있습니다.
    /// 빈 배열로 메시지를 전달하면 모든 참여자에게 메시지가 전달됩니다.
    func sendMessage(participantIds: [String], message: String) {
        Task { [weak self] in
            guard let self = self else { return }
            guard let room = self.room else { return }

            let result = await room.sendUserMessage(participantIds: participantIds, message: message)
            switch result {
            case .success():
                print("메시지 전송 성공")

            case .failure(let error):
                print("메시지 전송 실패, error:\(error.localizedDescription)")
            }
        }
    }

    // MARK: - UI 이벤트에 따른 처리

    /// 로컬미디어 토글 관련 처리
    ///
    /// 오디오, 비디오를 on/off 하거나 카메라의 위치를 변경하는 경우의 예시입니다.
    func bindLocalMedia() {

        // 비디오 on, off
        $video
            .sink { [weak self] flag in
                self?.media?.video.active = flag
            }
            .store(in: &cancelBag)

        // 오디오 On, off
        $audio
            .sink { [weak self] flag in
                self?.media?.audio.active = flag
            }
            .store(in: &cancelBag)

        // 카메라 front, back
        $cameraPosition
            .sink { [weak self] position in
                guard let self = self else { return }
                if self.media?.position == position { return }

                Task {
                    var mirror = false
                    if self.media?.position == .back {
                        mirror = true
                    }

                    try? await self.media?.switchCamera(position: position, isMirror:  mirror)
                }
            }
            .store(in: &cancelBag)
    }


    // 주기적으로 로컬 오디오 레벨을 얻어오기위한 예시입니다.
    func bindTimer() {
        levelTimer.combineLatest($status.filter { $0 == .connected})
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let room = self.room else { return }

                // 활성화된 원격 오디오의 레벨을 얻어옵니다.
                Task {
                    let local = self.media?.audioLevel ?? 0
                    let remote = await room.getAudioLevels()
                    await self.updateAudioLevel(local: local, remote: remote)
                }
            }
            .store(in: &cancelBag)


        statTimer.combineLatest($status.filter { $0 == .connected })
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let room = self.room else { return }

                Task {
                    let local = await room.getLocalQualityStatsReport()
                    let remote = await room.getRemoteQualityStatsReport()
                    await self.statistics.update(local: local, remote: remote)
                }
            }
            .store(in: &cancelBag)
    }

    @MainActor
    func updateAudioLevel(local: Int, remote: [String: Int]) {
        if let participant = self.participants[self.myId] {
            if participant.audio {
                participant.level = local

                if local == 0 {
                    participant.speaking = false
                } else {
                    participant.speaking = true
                }
            } else {
                participant.level = 0
                participant.speaking = false
            }
        }

        for (id, level) in remote {
            if let participant = self.participants[id] {
                participant.level = level
            }
        }
    }

    /// 로컬 미디어 카메라 위치를 전면, 후면 카메라로 변경합니다
    func switchCameraPosition(_ position: AVCaptureDevice.Position) {
        if media?.position == position { return }

        Task {
            var mirror = false
            if media?.position == .back {
                mirror = true
            }

            try? await self.media?.switchCamera(position: position, isMirror:  mirror)
        }
    }


    // MARK: - 화면공유

    /// 화면공유 예시입니다.
    ///
    /// 화면공유는 별도로 각 앱에서 broadcastExtension을 구성해야 합니다.
    /// 화면공유를 요청하면 broadcast picker가 익스텐션을 가져오는데, 여기에 표시되는 이름은
    /// broadcast extension의 display name 이 표시됩니다.
    /// 아래 루틴은 ConnetLive 인증처리와 broadcastExtension 호출 기능만을 담당합니다.
    func startScreenSharing() {
        guard let room = self.room else { return }

        // 화면공유는 시뮬레이터를 지원하지 않습니다.
        #if !targetEnvironment(simulator)
        try? room.requestScreenShare(appGroup: appGroup, extensionName: extensionBundleId) { [weak self] status in
            print("[startScreenSharing] 익스텐션 상태: \(status)")
            self?.screenShareStatus = status
        }
        #endif
    }

    /// 화면공유 중지
    ///
    /// Room 객체에 화면공유 중지를 요청합니다. 즉시 중지 처리 되며 중지 완료 이벤트는 전달되지 않습니다.
    /// 화면공유는 별도 프로세스로 동작하는 Broadcast extension을 사용합니다.
    /// extension은 중지 요청 후 각 세션 정리 및 extension 정리에 약 5초 정도의 시간을 필요로 합니다.
    /// extension에서 중지 얼럿이 표시되어야 종료가 완료된 것이므로, 다음 화면 공유는 최소 5초 이상 시간이 지난 후 시도해야 합니다.
    ///
    /// -Param : 화상회의 종료 여부
    func stopScreensharing(isLeftRoom: Bool = false) {
        guard let room = self.room else { return }
        room.stopScreenShare(isLeftRoom: isLeftRoom)
        self.screenShareStatus = .notAvailable
    }
}


