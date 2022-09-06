# Kakao i Connect Live 소개
- 카카오 i 커넥트 라이브(Kakao i Connect Live)는 개발자들이 라이브 스트리밍(Live Streaming) 서비스를 쉽게 개발하고 운영할 수 있는 환경을 제공하는 클라우드 기반 라이브 스트리밍 플랫폼(CPaaS: Communication Platform as a Service)입니다. 라이브 스트리밍 서비스 개발 시 필수 플랫폼인 CPaaS로서 통화, 방송, 회의, 하이브리드 서비스 개발을 지원합니다.

- 한국에서 가장 오랫동안 운영되고 있는 CPaaS로서 개발뿐만 아니라 운영에 필요한 경험과 안정성을 가지고 있으며, WebRTC 기술을 기반으로 어떠한 라이브 스트리밍 기술보다 빠른 레이턴시(Latency)와 우수한 호환성을 제공합니다. 또한, 기기의 성능이나 네트워크 상황에 따라 최적의 라이브 영상 서비스 구현을 위한 개발 도구인 카카오 i 커넥트 라이브 SDK와 클라우드 인프라를 제공합니다.


# iOS SDK 소개
- 별다른 서버 개발없이 라이브스트리밍 서비스를 개발할 수 있는 SDK 입니다.


# 지원 환경
- iOS 13 이상
- 지원 언어 : Swift
- 배포방식: Swift Package Manager
- Swift 최소 버전
```
ConnectLive SDK 2.2.0 : Swift 5.6.1, Xcode : 13.4
```
- bitcode 미지원


# 설치
Xcode > File > Add Packages
```
Name: ConnectLiveSDK
Version Rules: 2.2.0 - Next Minor
Location: https://github.com/kakaoi-clive/ios-sdk.git
```

# 예제
- 소스코드: https://github.com/kakaoi-clive/ios-sample

## 권한설정
### 카메라, 마이크 사용 권한 설정하기
ConnectLive SDK는 카메라와 마이크 권한이 필요하며, 앱 타겟의 Info에 아래 권한이 추가되어야 합니다.

```
Privacy - Camera Usage Description
Privacy - Microphone Usage Description
```


### 권한 체크 및 설정 이동
SDK에서는 별도의 권한 설정 기능이나 UI를 제공하지 않습니다.
각 서비스에 따라 UIKit, AVFoundation에서 제공하는 기능을 사용해 권한 여부와 요청, 설정 페이지 이동 등을 처리합니다.

```
AVCaptureDevice.authorizationStatus
AVCaptureDevice.requestAccess(for: AVMediaType)
UIApplication.shared.open(_ url: URL, 
                          options: [UIApplication.OpenExtenalURLOptionsKey:Any] = [:], 
                          completion: ((Bool) -> Void)? = nil)
```



## 인증
### 인증하기
Room 에 연결하기 위해서는 인증이 필요합니다. 콘솔에서 발급받은 서비스ID, 서비스키, 시크릿을 사용해 인증을 시도합니다.


```
ConnectLive.signIn( serviceId: String,
                    serviceSecret: String,
                    completion: @escaping ProvisionCallback)
```


### 인증해제
Room 연결 해제 후 기존 인증 토큰을 초기화 합니다. 
```
ConnectLive.signOut()
```

### 인증 콜백
SignIn 결과 및 에러 콜백
```
typealias ProvisionCallback = (_ code: Int, _ message: String) -> ()
```

### 인증 예시

```
import ConnectLiveSDK
 
func signIn() {
    // 인증수행
    ConnectLive.signIn(serviceId: "serviceId",
                       serviceSecret: "serviceSecret") { [weak self] code, message in
        if code == 0 {
            // 인증성공
        } else {
            // 인증실패
        }
    }
}
```

## iOS 오디오 설정
iOS의 경우 os의 오디오 세션을 별도 설정해 주어야 합니다.

### 오디오 세션 설정
```
ConnectLive.setAudioSessionConfiguration(category: AVAudioSession.Category,
                                         mode: AVAudioSession.Mode,
                                         options: AVAudioSession.CategoryOptions,
                                         delegate: AudioSessionDelegate? = nil)
```

### 오디오 세션 이벤트
오디오 세션 설정에서 delegate 를 지정해주면 오디오 세션 이벤트를 수신할 수 있습니다.

```
protocol AudioSessionDelegate {
    /// 다른앱이나 시스템이 오디오세션 제어를 가져감
    func didBeginInterruption()
     
    /// 다른앱이나 시스템이 오디오세션 제어를 반환
    func didEndInterruption(shouldResumeSession: Bool)
     
    /// 오디오세션의 장치 변경
    func didChangeRoute(reason:AVAudioSession.RouteChangeReason, previousRoute:AVAudioSessionRouteDescription)
     
    /// 시스템의 오디오세션 미디어서버 종료됨
    func mediaServerTerminated()
     
    /// 시스템의 오디오세션 미디어서버 초기화
    func mediaServerReset()
     
    /// 기타 오디오세션 상태관련 이벤트
    func didChangeCanPlayOrRecord(canPlayOrRecord: Bool)
    func didStartPlayOrRecord()
    func didStopPlayOrRecord()
    
    /// 오디오세션 활성화 이벤트
    func willSetActive(active: Bool)
    func didSetActive(active: Bool)
    func failedToSetActive(active: Bool, error: Error)
}
```

## Config
로컬 미디어 생성을 위한 LocalMediaOptions, 데이터 수신을 위한 리시버 설정을 위한 구조체입니다.

```
struct Config {
    /// 로컬 미디어 옵션
    var mediaOptions: LocalMediaOptions = LocalMediaOptions()

    /// 초기 생성할 영상 리시버의 수
    var videoReceiverInitialCount: Int = 9

    /// 최대 영상 리시버의 수
    var videoReceiverMaximumCount: Int = 20
}
```

### 로컬 미디어 옵션
Config 에 mediaOptions으로 로컬 미디어에 대한 기본 설정이 포함되어 있습니다. 필요한 경우 해당 설정을 수정해 로컬 미디어 생성시 전달할 수 있습니다.
 
```
struct LocalMediaOptions {
    /// 비디오 소스
    var source: CapturerType = .camera

    /// 비디오 유무
    var hasAudio: Bool = true

    /// 오디오 유무
    var hasVideo: Bool = true

    /// 생성시 비디오 활성화
    var video: Bool = true

    /// 생성시 오디오 활성화
    var audio: Bool = true

    /// 비디오 식별을 위한 커스텀 문자열
    var extraValue: String = ""

    /// 카메라 회전 방식
    var rotationType: CameraRotationType = .notAvailable

    /// 카메라 기본 위치
    var position: AVCaptureDevice.Position = .front

    /// 카메라 좌우 반전 여부
    var isMirror: Bool = true

    /// 시뮬레이터 카메라 대체 재생용 파일명
    var fileName: String = "sample.mov"

    /// 카메라 캡처 너비
    var cameraCapturewWidth: Int = 640

    /// 카메라 캡처 높이
    var cameraCaptureHeight: Int = 480

    /// 오디오 타입
    var audioType: AudioProcessingType = .voice

    /// AGC 유무
    var autoGain: Bool = false
}
```

### 로컬 미디어 옵션 : 비디오 소스(캡처러 타입)
비디오 소스는 camera, file, by-pass 캡처러로 구분되며, camera는 실단말에서만 지원합니다.

시뮬레이터의 경우 file로 고정되며, 프로젝트내에 포함된 mov 파일을 fileName에 설정해야 합니다.

```
enum CapturerType {
    /// 카메라
    case camera

    /// 바이패스
    case bypass

    /// 파일
    case file
}
```

### 미디어 옵션 : 오디오 타입(오디오 프로세싱 타입)
오디오 타입은 마이크 입력에 에코 캔슬 적용 여부를 설정합니다.

voice 인 경우 echo cancellation 기능을 활성화하며, music의 경우는 echo cancellation을 활성화하지 않습니다.  

```
enum AudioProcessingType: String {
    case voice
    case music
}
```


### 리시버 설정
다른 참여자의 영상은 구독과 해제를 통해 미디어 스트림을 수신하게 됩니다.

스트림 수신은 통신환경과 단말 성능, 서비스 품질과 관련이 많으므로
가급적 제한된 수의 스트림만을 사용해야합니다.

특정갯수의 리시버를 설정해 놓으면 비디오 구독시 해당 리시버 구성 내에서만 구독이 이루어지게 됩니다.
구독 요청시 리시버 수가 부족한 경우 오류가 발생하므로, 다른 영상의 구독을 해제한 뒤에 사용해야 합니다.

```
/// 초기 생성할 영상 리시버의 수
var videoReceiverInitialCount: Int = 9

/// 최대 영상 리시버의 수
var videoReceiverMaximumCount: Int = 20

/// 영상 리시버가 부족한 경우 증가 단위(아직 지원하지 않음)
var videoReceiverGrowthRate: Int = 1
```


## LocalMedia
로컬 캡처러와 로컬 렌더러를 관리하기 위한 클래스 입니다.

```
protocol LocalMedia {
    var video: LocalVideo { get }
    var audio: LocalAudio { get }
    var position: AVCaptureDevice.Position { get set }
    var isMirror: Bool { get }
    var audioLevel: Int { get }

    func start() async throws
    func start(completion: @escaping (Error?) -> ())
    func stop()
    func switchCamera(position: AVCaptureDevice.Position, isMirror: Bool) async throws
    func switchCamera(position: AVCaptureDevice.Position, isMirror: Bool, completion: @escaping (Error?) -> ())
}
```

### 미디어 생성
LocalMediaOptions 설정을 기반으로 로컬 미디어를 생성합니다.
```
ConnectLive.createLocalMedia(options: LocalMediaOptions) -> LocalMedia?
```

### 로컬 미디어 스트림
로컬 미디어는 오디오, 비디오 스트림 정보 객체를 포함하고 있습니다.

```
/// 로컬 비디오 스트림
var video: LocalVideo { get }
 
/// 로컬 오디오 스트림
var audio: LocalAudio { get }
```


### 로컬 미디어 시작
로컬 미디어(캡처러) 동작을 시작합니다.

로컬 비디오 스트림 video 객체에 렌더러가 연결되어 있으면 로걸 비디오 화면이 재생됩니다.
명시적으로 호출해 주지 않아도 미디어 퍼블리싱이 시작되면 자동으로 호출됩니다.

```
func start() async throws
func start(completion: @escaping (Error?) -> ())
```

### 로컬 미디어 중지
```
func stop() async
func stop(completion: @escaping () -> ())
```


### 카메라 관련 기능
iOS 카메라 관련 제어를 위한 기능들을 제공합니다.

카메라 위치 가져오거나 변경
```
var position: AVCaptureDevice.Position { get set }
```

카메라 좌우 반전 여부
```
var isMirror: Bool { get }
```
 
카메라 전환
```
func switchCamera(position: AVCaptureDevice.Position, isMirror: Bool) async throws
func switchCamera(position: AVCaptureDevice.Position, isMirror: Bool, completion: @escaping (Error?) -> ())
```

### 로컬 미디어 생성 예시

``` 
// 로컬 미디어 옵션
var config = Config()
config.mediaOptions.audio = true
config.mediaOptions.video = true
  
// 로컬 미디어 생성
let media = ConnectLive.createLocalMedia(options: config.mediaOptions)


// 미디어 객체내 기능 호출
Task {
    try? await media?.switchCamera(position: .back, isMirror: true) 
}

```


## Room
ConnectLive 의 실제 화상회의가 이루어지는 객체입니다.


### 룸 생성
룸 객체를 생성합니다. 룸 이벤트를 위한 RoomDelegate를 함께 전달합니다.
```
ConnectLive.createRoom(config: Config, delegate: RoomDelegate) -> Room
```

### 로컬 미디어 퍼블리싱
룸 객체가 생성되면 로컬 미디어를 이 룸에서 퍼블리싱하도록 설정합니다.

아직 룸에 연결된 상태가 아닌 경우 연결 후에 퍼블리싱이 이루어집니다.

```
func publish(_ media: LocalMedia?) throws
```

### Room 연결
룸에 연결합니다. 데이터 채널 생성 및 sdp 교환 등 실제 RTP 스트림 송수신을 위한 모든 절차가 진행됩니다.
```
func connect(roomId: String)
```
 
 
 ### 연결해제
```
func disconnect()
```

### 참여자 얻기
룸 연결 후 룸 내의 현재 참여자 관련 정보들을 얻어올 수 있습니다.

```
/// 로컬 참여자
var localParticipant: LocalParticipant { get}
 
/// 참여자 가져오기
///
/// 참여자 목록에서 해당 id에 해당하는 참여자 객체를 반환합니다.
var remoteParticipants: [String: RemoteParticipant] { get }
 
/// 구독중인 비디오 사용자 목록
func getVideoOccupants() -> [String, RemoteParticipant]
 
/// 서버에서 오디오에 할당된 사용자 목록
func getAudioOccupants() -> [String, RemoteParticipant]
```


### 비디오 구독
비디오는 자동으로 수신되지 않으며, 구독을 통해 수신 여부를 결정합니다.

Config에서 설정된 최대 리시버 수 이상 구독할 수 없으며, 구독 수 만큼 데이터 트래픽이 발생하므로 필요로하는 비디오만 구독해야 합니다.
Room의 참여자 테이블에는 각 참여자 정보가 포함되는데, 참여자 정보에는 각 스트림 정보를 포함하고 있습니다.
참여자의 비디오 스트림ID를 통해 구독을 요청합니다.

여러개의 구독을 요청하는 경우 에러발생시 RoomDelegate의 onError를 통해 이벤트가 전달되며,
개별 요청하는 경우 콜백을 통해 이벤트가 전달됩니다. 

```
func subscribe(videoIds:[Int])
func subscribe(videoId: Int) async -> Result<Void, Error>
func subscribe(videoId: Int, completion: @escaping (Result<Void, Error>) -> Void )
```

### 비디오 구독 해제
```
func unsubscribe(videoIds:[Int])
func unsubscribe(videoId: Int) async -> Result<Void, Error>
func unsubscribe(videoId: Int, completion: @escaping (Result<Void, Error>) -> Void )
```


### 화면공유 요청
iOS 화면공유는 앱에서 별도 타겟으로 구현하게 됩니다.

앱에서는 화면 공유를 위한 요청만 처리하고, 실제 화면 공유는 앱의 extension 에서 처리합니다.
룸에서는 화면 공유 요청시 iOS Broadcast Picker를 표시하고, 익스텐션을 실행하게 됩니다.

앱 그룹과 Broadcast Extension의 번들ID를 설정해야 합니다.

```
/// 화면 공유 요청
func requestScreenShare(appGroup: String,
                        extensionName: String,
                        completion: @escaping (ScreenShareData.ExtensionStatus)->Void) throws
 
/// 화면 공유 중지 요청
func stopScreenSahre(isLeftRoom: Bool)
```


### Stat 정보
RTC statistics 기반한 데이터 얻기

```
/// 현재 활성화된 리모트 오디오 레벨 얻기
/// 모든 참여자의 오디오 레벨이 전달되지 않고, 현재 활성화된 참여자의 오디오 레벨만 전달됩니다.
func getAudioLevels(completion: @escaping ([String: Int]) -> () )
 
/// 송신 세션의 stat 정보 목록
func getLocalStatsReport(completion: @escaping ([String: Statistics]) -> ())
 
/// 수신 세션의 stat 정보 목록
func getRemoteStatsReport(completion: @escaping ([String: Statistics]) -> ())
```

Statistics 데이터
```
struct Statistics {
    var id: String
    var type: String
    var timeStamp: CFTimeInterval
    var values: [String: Any]
}
```



### 모든 수신 오디오 차단
서비스에서 모든 수신오디오를 활성화, 비활성화
```
/// 모든 수신 오디오 차단
func setMuted(_ isMuted: Bool)
```


### 메시지 전송
특정 유저에게 메시지를 전달합니다.
participantIds 배열에 지정된 참여자ID에 해당하는 참여자들에게 메시지가 전달되고,
빈 배열을 지정하면 전체 참여자에게 메시지가 전달됩니다. 
```
func sendUserMessage(participantIds:[String], message: String, completion: @escaping (Result<Void, Error> -> Void)
```



## RoomDelegate
앱에서 상태에 맞는 UI 변경을 처리하기 위해 이벤트 delegate를 room 생성 시 전달합니다.


### 콜백별 이벤트 내용
```
protocol RoomDelegate {
    /// 룸 연결 이벤트
    ///
    /// - Param progress: 진행률
    func onConnecting(progress: Float)
     
    /// 룸 연결 성공 이벤트
    ///
    /// 룸 입장시에 룸에 참여중인 사용자 목록이 전달됩니다.
    ///
    /// - Param participantIds: 참여자 id 목록
    func onConnected(participantIds: [String])
     
    /// 룸 연결 해제 이벤트
    ///
    /// 직접 연결을 해제한 경우와 오류로 연결이 해제된 경우 모두 이벤트가 발생합니다.
    func onDisconnected(reason: DisconnectReason)
     
    /// 에러 이벤트
    ///
    /// 에러가 먼저 발생하고, 룸 연결 해제 이벤트가 발생합니다.
    ///
    /// - Params
    ///     - code: 에러코드
    ///     - message: 에러 메시지
    ///     - isCritical: 연결이 종료되는 오류로 onError 발생후 연결이 즉시 종료됩니다.
    func onError(code: Int, message: String, isCritical: Bool)
     
     
    /// 참여자 입장 이벤트
    ///
    /// - Param remoteParticipant: 참여자
    func onParticipantEntered(remoteParticipant: RemoteParticipant)
     
    /// 참여자 퇴장 이벤트
    ///
    /// - Param remoteParticipant: 참여자
    func onParticipantLeft(remoteParticipant: RemoteParticipant)
     
     
    /// 자신의 로컬 미디어 송출
    ///
    /// - Param localMedia: 발행되는 로컬 미디어
    func onLocalMediaPublished(localMedia: LocalMedia?)
     
    /// 자신의 로컬 미디어 송출 중지
    ///
    /// - Param localMedia: 발행 중지되는 로컬 미디어
    func onLocalMediaUnpublished(localMedia: LocalMedia?)
     
     
    /// 참여자의 비디오 송출 이벤트
    ///
    /// - Param remoteParticipant: 참여자
    func onRemoteVideoPublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo)
     
     
    /// 참여자의 비디오 송출 중지
    ///
    /// - Param remoteParticipant: 참여자
    func onRemoteVideoUnpublished(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo)
     
     
    /// 참여자의 오디오 송출 이벤트
    ///
    /// - Params
    ///     - remoteParticipant: 참여자
    ///     - remoteAudio: 참여자 오디오
    func onRemoteAudioPublished(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio)
     
    /// 참여자의 오디오 송출 중지
    ///
    /// - Params
    ///     - remoteParticipant: 참여자
    ///     - remoteAudio: 참여자 오디오
    func onRemoteAudioUnpublished(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio)
     
     
    /// 참여자의 오디오 구독 시작
    ///
    /// 오디오는 서버에서 활성 사용자를 기반으로 자동으로 구독, 해제 됩니다.
    ///
    /// - Params
    ///     - remoteParticipant: 참여자
    ///     - remoteAudio : 참여자의 오디오
    func onRemoteAudioSubscribed(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio)
     
    /// 참여자의 오디오 구독 해제
    ///
    /// - Params
    ///     - remopteParticipant: 참여자
    ///     - remoteAudio : 참여자의 오디오
    func onRemoteAudioUnsubscribed(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio)
     
     
    /// 참여자의 비디오 상태 변경
    ///
    /// - Params
    ///     - remoteParticipant: 참여자
    ///     - remoteVideo: 참여자의 비디오
    func onRemoteVideoStateChanged(remoteParticipant: RemoteParticipant, remoteVideo: RemoteVideo)
     
    /// 참여자의 오디오 상태 변경
    ///
    /// - Params
    ///     - remoteParticipant: 참여자
    ///     - remoteAudio: 참여자의 오디오
    func onRemoteAudioStateChanged(remoteParticipant: RemoteParticipant, remoteAudio: RemoteAudio)
    
    
    /// 메시지 수신
    ///
    /// - Params
    ///     - senderId: 메시지 송신한 참여자 id
    ///     - message: 메시지
    func onUserMessage(senderId: String, message: String)
}
```



## Participant
로컬, 리모트 참여자 객체입니다.

키값으로 String 타입의 id 제공하며, Room의 참여자 테이블과 RoomDelegate를 통해 전달됩니다.
오브젝트 타입이므로, 참조 후 별도 저장 시 레퍼런스 카운터를 관리해야 룸 해제시에 참여자들도 정상 해제됩니다.

### LocalParticipant
```
protocol LocalParticipant {
    /// 참가자 id
    var id: String
     
    /// 비디오 스트림 목록
    var videos: [Int: LocalVideo]
     
    /// 오디오 스트림 목록
    var audios: [Int: LocalAudio]
}
```

### RemoteParticipant
```
protocol RemoteParticipant {
    /// 참가자 id
    var id: String
     
    /// 비디오 스트림 목록
    var videos: [Int: RemoteVideo]
     
    /// 오디오 스트림 목록
    var audios: [Int: RemoteAudio]
     
    /// 비디오 구독 여부
    var isVideoSubscribed: Bool
}
```



## Local Video/Audio
로컬 미디어, 로컬 참여자에 포함되어 있으며, 송출하는 비디오, 오디오 스트림 관련 객체입니다.

### LocalVideo
로컬 미디어 생성 시 각 항목은 기본값으로 생성되며, 미디어를 퍼블리싱 한 이후에 각 값이 설정됩니다.
 
```
protocol LocalVideo {
    /// 비디오의 스트림id
    var id: Int { get }

    /// 비디오 소유자(참가자id)
    var owner: String { get }

    /// 비디오 활성화 여부
    var active: Bool { get set }

    /// 식별을 위한 추가 레이블
    var extraValue: String { get set }

    /// 연결된 렌더뷰 id
    var viewId: String { get }

    var hd: Bool { get set }
    
    /// 렌더뷰 연결
    func attach(_ view: UIRenderView)

    /// 렌더뷰 해제
    func detach()
}

```


### LocalVideo : 뷰 연결
비디오 스트림에 UIRenderView를 붙여 비디오를 화면에 렌더링할 수 있습니다.
구독이 시작되면 스트림이 수신되고, 설정된 렌더러로 화면이 보여지게 됩니다.

```
/// 렌더뷰 붙이기
func attach(_ view: UIRenderView)

/// 렌더뷰 해제
func detach()
```

 
### LocalAudio
오디오 스트림 정보입니다.

```
protocol LocalAudio {
    /// 오디오의 스트림id
    var id: Int { get }
     
    /// 오디오 소유자(참가자id)
    var owner: String { get }
     
    /// 오디오 활성화 여부
    var active: Bool { get set }
         
    /// 식별을 위한 추가 레이블
    var extraValue: String { get set }
}

```



## Remote Video/Audio
원격 참여자의 비디오, 오디오 스트림 객체입니다. 참여자 객체나 Room delegate를 통해 전달됩니다.

### RemoteVideo
원격 참여자가 비디오를 퍼블리싱 하게 되면 생성되는 객체입니다. 

원격 참여자와 스트림 정보를 포함하며, LocalVideo와 마찬가지로 UIRenderView를 붙이거나 떼어낼 수 있습니다.

```
protocol RemoteVideo {
    /// 비디오의 스트림id
    var id: Int { get }
     
    /// 비디오 소유자(참가자id)
    var owner: String { get }
     
    /// 비디오 활성화 여부
    var active: Bool { get }
     
    /// 식별을 위한 추가 레이블
    var extraValue: String { get }
     
    /// 비디오 프로파일
    var profile: VideoProfileType { get }
     
    /// 일시 중지
    var pause: Bool { get set }
     
    /// 연결된 렌더뷰 id
    var viewId: String { get }
     
    /// 구독여부
    var isSubscribed: Bool { get }
     
    /// 렌더뷰 연결
    func attach(_ view: UIRenderView)
     
    /// 렌더뷰 해제
    func detach(_ view: UIRenderView)
     
    /// 스트림 일시 중지
    func setPaused(_ pause: Bool) throws
     
    /// 비디오 프로파일 변경
    func setProfile(_ profile: VideoProfileType) throws
}
```



### RemoteAudio
오디오를 퍼블리싱 하게 되면 생성되는 객체입니다.

```
protocol RemoteAudio {
    /// 오디오의 스트림id
    var id: Int { get }
     
    /// 오디오 소유자(참가자id)
    var owner: String { get }
     
    /// 오디오 활성화 여부
    var active: Bool { get }
     
    /// 식별을 위한 추가 레이블
    var extraValue: String { get }
     
    /// 오디오 항상 활성화
    var alwaysOn: Bool { get }
}
```





## 화면공유 Extension
iOS는 앱단에서 구성하는 boradcastExtension 에서 화면 캡처와 송출을 담당하고, sdk 측에서는 해당 익스텐션과의 연동 처리를 담당합니다.


### 구성
애플 앱 그룹 등록
```
developer.apple.com 에서 앱 그룹을 등록
앱 프로파일에 앱 그룹 추가
```

익스텐션 타겟 추가 합니다.
```
프로젝트 Targets > Broadcast Extension을 추가
```

프로젝트 설정
```
앱 그룹 추가 : Signing & Capabilities > App Groups
extension의 Display Name 설정 : General > Display Name
Extension의 클래스명 설정 : Info > NSExtension > NSExtensionPrincipalClass
```

Room의 화면공유 시작, 중지 메쏘드 호출


### 화면공유 시작 예시
화면공유를 요청하면 broadcast picker가 익스텐션을 가져오는데, 여기에 표시되는 이름은
broadcast extension의 display name 에 설정된 값이 표시됩니다.

아래 루틴은 ConnetLive 인증처리와 broadcastExtension 호출 기능만을 담당합니다.

```
@Published var screenShareStatus: ScreenShareData.ExtensionStatus = .notAvailable

func startScreenSharing() {
    guard let room = self.room else { return }
    
    let appGroup = ""
    let extensionBundleId = ""
    
    // 화면공유는 시뮬레이터를 지원하지 않습니다.
    #if !targetEnvironment(simulator)
    try? room.requestScreenShare(appGroup: appGroup, extensionName: extensionBundleId) { [weak self] status in
        print("[startScreenSharing] 익스텐션 상태: \(status)")
        self?.screenShareStatus = status
    }
    #endif
}
```

### 화면공유 중지 예시
Room 객체에 화면공유 중지를 요청합니다. 

화면공유 상태가 즉시 중지 상태로 변경되며 완료 이벤트는 추가로 전달되지 않습니다.

화면공유는 별도 프로세스로 동작하는 Broadcast extension을 사용합니다.
extension은 중지 요청 후 각 세션 정리 및 extension 정리에 약 5초 정도의 시간을 필요로 합니다.
iOS에서 자체적으로 표시하는 Broadcast 중지 얼럿이 표시되어야 종료가 완료된 것이므로, 
다음 화면 공유는 최소 5초 이상 시간이 지난 후 시도해야 합니다.

```
@Published var screenShareStatus: ScreenShareData.ExtensionStatus = .notAvailable

func stopScreensharing(isLeftRoom: Bool = false) {
    guard let room = self.room else { return }
    room.stopScreenShare(isLeftRoom: isLeftRoom)
    self.screenShareStatus = .notAvailable
}
```


### 익스텐션 콜백
룸에 화면공유를 요청하면 ScreenShareData.ExtensionStatus 값이 익스텐션의 상태에 따라 콜백으로 전달됩니다.

```
public enum ExtensionStatus: Int {
    case notAvailable       = 0
    case broadcastReady     = 1
    case broadcastStarted   = 2
    case broadcastClosed    = 3
}
```



### 화면공유 익스텐션 예시

```
class ConnectLiveSampleHandler: RPBroadcastSampleHandler {
    let appGroupName = "group.xxxx"
    var screenShare: ScreenShare?
    var disconnectSemaphore: DispatchSemaphore?
 
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
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
 
            let message =  NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.main, value: "", comment: "").appending(msg)
            let userInfo = [NSLocalizedFailureReasonErrorKey: message]
            let error = NSError(domain: "app.domain.***", code: -1, userInfo: userInfo)
            self.finishBroadcastWithError(error)
        }
    }
 
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        screenShare?.pause()
    }
 
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        screenShare?.resume()
    }
 
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        screenShare?.stop { [weak self] in
            self?.disconnectSemaphore?.signal()
        }
 
        disconnectSemaphore?.wait()
        screenShare = nil
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
```


# 문서 및 링크
- https://docs.kakaoi.ai/connect_live/
- https://connectlive.kakaoi.ai/

