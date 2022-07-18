//
//  ServiceParticipant.swift
//  conference
//

import Foundation

/// 서비스 참여자 정보
///
/// 서비스에서는 SDK에서 알수 없는 사용자 이름, id 같은 서비스 종속 정보와 UI 업데이를 위한 데이터들를 위해
/// 별도의 참여자 데이터를 구성하게 됩니다.
class ServiceParticipant: ObservableObject, Identifiable {
    var id: String
    var videos: [Int] = []
    
    @Published var level: Int = 0
    @Published var audio: Bool
    @Published var video: Bool
    @Published var screen: Bool = false
    @Published var speaking: Bool = false
    
    init(id: String, audio: Bool = false, video: Bool = false) {
        self.id = id
        self.audio = audio
        self.video = video
    }
}
