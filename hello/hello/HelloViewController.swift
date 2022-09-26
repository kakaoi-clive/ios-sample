//
//  HelloViewController.swift
//  hello
//

import UIKit
import ConnectLiveSDK

/// Hello ConnectLive
///
/// ConnectLive Room 접속을 테스트하기 위한 샘플입니다.
/// 인증과 룸 접속을 위한 최소의 기능만을 사용하므로, 실제 앱 개발과는 차이가 있습니다.
class HelloViewController: UIViewController {
    @IBOutlet weak var localView: RenderView!
    @IBOutlet weak var remoteView: RenderView!
    @IBOutlet weak var button: UIButton!


    /// 콘솔에서 발급받은 서비스 정보를 입력합니다.
    let serviceId: String = "ICLEXMPLPUBL"
    let serviceSecret: String = "ICLEXMPLPUBL0KEY:YOUR0SRVC0SECRET"


    /// 접속할 룸ID 를 입력합니다.
    ///
    /// 동일한 룸 id인 경우 상호 연결이 이루어지므로 무료 인증을 사용하시는 경우 주의하시기 바랍니다.
    /// 룸 생성 시 매번 새로운 룸 id를 사용하고, 복잡한 문자열을 사용하기를 추천드립니다.
    /// 룸 id 는 32자 이내, 영문, 숫자, - 만 사용할 수 있습니다.
    let roomId: String = ""


    /// ConnectLive sdk 관련 객체
    var config = Config()
    var room: Room?
    var media: LocalMedia?


    /// 샘플에서 사용하는 프로퍼티
    var participants: [String] = []
    var currentRemoteParticipantId: String = ""

    enum Status {
        case disconnected
        case connecting
        case connected
    }
    var currentStatus: Status = .disconnected



    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if self.roomId.isEmpty {
            assertionFailure("설명을 참조해 self.roomId 프로퍼티에 접속할 룸 id를 입력하세요.")
        }



        // 오디오 세션 설정
        // 모든 앱은 아래와 같이 오디오 세션 설정이 이루어져야 합니다.
        ConnectLive.setAudioSessionConfiguration(category: .playAndRecord,
                                                 mode: .default,
                                                 options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth],
                                                 delegate: nil)

        // 로컬 미디어 생성
        createLocalMedia()
    }


    // 연결하기 버튼 이벤트
    @IBAction func onButton(_ sender: Any) {
        if self.currentStatus == .disconnected {
            /// 인증은 룸에 접속하기전 이루어져야 합니다. 따라서, 앱의 구현에 따라 인증 위치는 변경될 수 있습니다.
            ConnectLive.signIn(serviceId: serviceId, serviceSecret: serviceSecret) { [weak self] code, message in
                if code == 0 {
                    self?.connectRoom(roomId: self?.roomId ?? "")
                } else {
                    assertionFailure(message)
                }
            }

        } else {
            disconnectRoom()
            
            /// ConnectLive 사용이 완료되면 인증을 해제해 주어야 합니다.
            ConnectLive.signOut()
        }
    }


    /// 로컬 미디어 생성
    ///
    /// 카메라 설정과 로컬뷰 설정 등이 이루어집니다.
    func createLocalMedia() {
        if self.media != nil { return }

        // 로컬 미디어 설정
        // 카메라 위치
        config.mediaOptions.position = .front

        // 카메라 회전 방식
        config.mediaOptions.rotationType = .appOrientation

        // 시뮬레이터를 사용하는 경우 카메라 대신 재생할 파일 지정
        config.mediaOptions.fileName = "test.mov"


        guard let media = ConnectLive.createLocalMedia(config: config) else {
            assertionFailure("카메라 캡처러 생성 실패")
            return
        }

        // 로컬뷰
        media.video.attach(localView)

        // 미디어 시작
        media.start { error in
            if let error = error {
                // 미디어 시작 오류
                // 시뮬레이터인 경우 위 설정에서 지정한(test.mov) 파일을 프로젝트에 등록한 후 실행하세요.
                assertionFailure(error.localizedDescription)
            }
        }

        self.media = media
    }


    /// 룸 접속
    func connectRoom(roomId: String) {
        // 룸 객체 생성
        let room = ConnectLive.createRoom(config: config, delegate: self)

        // 룸 입장
        room.connect(roomId: roomId)

        // 로컬 미디어 게시
        // 원하는 시점에 호출할 수 있으며, 미리 호출한 경우 룸 입장 및 송출 세션 연결 이후에 게시됩니다.
        try? room.publish(self.media)

        self.room = room
    }


    /// 룸 접속 해제
    func disconnectRoom() {
        room?.disconnect()
    }



    /// 이 샘플은 룸에 연결하는 가장 단순한 예제이므로, 1명의 리모트 유저만 선택해 화면에 보여줍니다.
    /// 리모트 유저를 화면에 표시하기 위해 리모트 유저의 비디오를 구독하고, 리모트 유저의 비디오에 렌더러를 연결해 주어야 합니다.
    func updateRemoteView() {
        guard let room = self.room else { return }

        // 참여자가 없는 경우 리턴
        if participants.count == 0 { return }

        // 이미 선택된 사용자가 있는 경우 리턴
        if !self.currentRemoteParticipantId.isEmpty { return }

        if let id = participants.first(where: { $0 != room.localParticipant.id }) {
            self.currentRemoteParticipantId = id

            // 해당 참여자 비디오 구독
            subscribeVideo(participantId: id)

            // 해당 참여자 비디오에 렌더러 연결
            attachRenderer(participantId: id, renderView: self.remoteView)
        }
    }


    /// 비디오 스트림에 렌더뷰(UIRenderView)를 첨부합니다.
    ///
    /// 구독중인 비디오 스트림에 렌더뷰를 첨부하면, 비디오 스트림으로 전달되는 데이터를 해당 뷰에 표시하게 됩니다.
    /// 만약 렌더뷰가 이미 다른 스트림이 첨부되어 있는 경우 기존 연결은 분리됩니다.
    func attachRenderer(participantId: String, renderView: RenderView) {
        guard let room = self.room else { return }

        // id로 실제 참여자 객체를 얻습니다.
        guard let participant = room.remoteParticipants[participantId] else { return }

        // 해당 참여자의 video를 얻습니다.
        guard let remoteVideo = participant.videos.values.first else { return }

        // 비디오에 뷰 설정
        remoteVideo.attach(renderView)
    }


    /// 상대방의 비디오를 구독하는 예시입니다.
    ///
    /// 오디오의 경우 발화자에 따라 자동으로 구독, 해제가 이루어지므로 추가적인 처리없이 상대방의 소리를 수신하게 됩니다.
    /// 비디오의 경우에는 자동적으로 구독이 이루어지지 않으므로, 서비스별 화면 구성에 맞게 비디오 구독 여부를 결정해야 합니다.
    /// 구독을 통해 상대방의 비디오를 수신하기 위해서는 Room의 remoteParticipants에서 해당 참여자의 비디오 스트림id를 얻어
    /// 직접 구독 처리를 진행해야 합니다.
    ///
    /// 비디오 구독수가 늘어날수록 많은 데이터와 자원을 사용하게 되므로, 필요한 비디오만을 구독해야 합니다.
    /// 특히 화면을 다른 참여자로 변경하는 경우 기존 구독을 해제해야 불필요한 데이터의 수신을 막을 수 있습니다.
    func subscribeVideo(participantId: String) {
        print("[subscribe] 참여자 비디오 스트림 할당 요청, \(participantId)")
        guard let room = self.room else { return }

        // id로 실제 참여자 객체를 얻습니다.
        guard let participant = room.remoteParticipants[participantId] else { return }

        // 해당 참여자의 video를 얻습니다.
        guard let remoteVideo = participant.videos.values.first else { return }

        // 비디오 구독 여부 확인
        if remoteVideo.isSubscribed {
            print("[subscribe] \(participantId)의 remoteVideo 이미 구독 중")
            return
        }

        // 비디오 구독
        room.subscribe(videoId: remoteVideo.id) { result in
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
}


/// 룸 이벤트입니다.
/// 메쏘드에 대한 설명은 RoomDelegate를 참조하시기 바랍니다.
extension HelloViewController: RoomDelegate {
    func onConnecting(progress: Float) {
        print("[onConnecting] progress:\(progress)")
        self.button.isEnabled = false
        self.currentStatus = .connecting
    }

    func onConnected(participantIds: [String]) {
        print("[onConnected] ids:\(participantIds)")
        self.button.isEnabled = true
        self.button.setTitle("Disconnect", for: .normal)
        self.currentStatus = .connected


        self.participants = participantIds
        updateRemoteView()
    }

    func onDisconnected(reason: DisconnectReason) {
        print("[onDisconnected] reason:\(reason)")
        self.button.isEnabled = true
        self.button.setTitle("Join", for: .normal)
        self.currentStatus = .disconnected



        // 테스트 연결이 종료되면 앱을 종료 시킵니다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        }
    }

    func onError(code: Int, message: String, isCritical: Bool) {
        print("[onError] code:\(code), message:\(message), isCritical: \(isCritical)")
    }

    func onParticipantEntered(remoteParticipant: RemoteParticipant) {
        self.participants.append(remoteParticipant.id)
    }

    func onParticipantLeft(remoteParticipant: RemoteParticipant) {
        self.participants.removeAll(where: { $0 == remoteParticipant.id })
        if self.currentRemoteParticipantId == remoteParticipant.id {
            self.currentRemoteParticipantId = ""
            updateRemoteView()
        }
    }

    func onRemoteVideoPublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo) {
        updateRemoteView()
    }

    func onRemoteVideoUnpublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo) {
        if self.currentRemoteParticipantId == remoteParticipant.id {
            self.currentRemoteParticipantId = ""
            updateRemoteView()
        }
    }
}
