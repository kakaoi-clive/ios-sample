//
//  Provisioning.swift
//  conference
//

import Foundation
import Combine
import _Concurrency
import ConnectLiveSDK



/// ConnectLive 서비스를 사용하기 위한 인증을 처리하는 클래스입니다.
///
/// 콘솔에서 발급받은 서비스별 인증 정보를 반영해 인증을 진행합니다.
class Provisioning: ObservableObject {

    /// 콘솔에서 발급받은 서비스 정보
    @Published var serviceId: String = "ICLEXMPLPUBL"
    @Published var serviceSecret: String = "ICLEXMPLPUBL0KEY:YOUR0SRVC0SECRET"

    /// 인증서버 주소입니다.
    @Published var provisioningEndpoint: String = ""

    /// 별도의 자체 인증을 사용하는 경우의 토큰 정보입니다.
    @Published var externalToken: String = ""


    @Published var apiServer: String = ""

    /// 별도의 TURN 서버 구성을 사용하는 경우 설정합니다.
    @Published var turnServer: String = ""
    @Published var turnUsername: String = ""
    @Published var turnCredential: String = ""

    init() {
    }

    @MainActor
    func signIn() async -> RoomError? {
        let result = await ConnectLive.signIn(serviceId: serviceId, serviceSecret: serviceSecret, endpoint: provisioningEndpoint)
        if result.0 == 0 {
            return nil
        } else {
            // 인증오류
            print("signIn failed, code:\(result.0), message:\(result.1)")
            return RoomError(code: result.0, message: result.1, isCritical: true)
        }
    }

    func signOut() {
        ConnectLive.signOut()
    }
}
