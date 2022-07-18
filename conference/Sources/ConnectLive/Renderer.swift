//
//  Renderer.swift
//  conference
//

import Foundation
import SwiftUI

/// 뷰 업데이트시 렌더러 초기화를 막기위해 별도 클래스로 구성
///
/// 이 샘플에서는 제한된 뷰만 사용하기 위해 렌더러를 미리 생성해 놓습니다.
/// 렌더러는 Metal을 사용해 비디오 프레임을 렌더링하며, 많은 뷰가 생성될 수록 메모리 사용량이 증가합니다.
/// 참여자의 비디오 스트림을 구독하고, 비디오 스트림에 렌더러를 연결해주어야 비디오가 표시됩니다.
class Renderer {
    // const
    static let remoteViewCount = 14

    // views
    var localView: RenderView = RenderView(contentMode: .scaleAspectFill)
    var remoteViews: [ParticipantVideoItem: RenderView] = [:]
    var availableViews: [RenderView] = []

    init() {
        for _ in 0..<Renderer.remoteViewCount {
            availableViews.append(RenderView(contentMode: .scaleAspectFill))
        }
    }

    func isAvailable() -> Bool {
        return !availableViews.isEmpty
    }

    @ViewBuilder
    func getView(item: ParticipantVideoItem) -> some View {
        remoteViews[item]
    }

    func attach(item: ParticipantVideoItem) {
        if availableViews.isEmpty { return }
        let view = availableViews.removeFirst()
        remoteViews[item] = view
    }

    func detach(item: ParticipantVideoItem) {
        if let view = remoteViews[item] {
            availableViews.append(view)
        }
    }

}
