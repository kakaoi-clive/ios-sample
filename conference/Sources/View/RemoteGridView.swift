//
//  RemoteGridView.swift
//  conference
//

import Foundation
import SwiftUI

struct RemoteGridView: View {
    var renderer: Renderer
    @ObservedObject var conference: Conference

    @State private var currentVideos: [ParticipantVideoItem] = []

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160, maximum: 180))
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(currentVideos, id: \.self) { item in
                VStack {
                    getView(item: item)
                    Text("\(item.pid)")
                }
            }
        }
        .valueChanged(value: conference.currentParticipantVideos) { participants in
            updateParticipantVideos(participants)
        }
        .onAppear {
            updateParticipantVideos(conference.currentParticipantVideos)
        }
    }


    @ViewBuilder
    func getView(item: ParticipantVideoItem) -> some View {
        renderer.getView(item: item)
            .frame(width: 160, height: 160)
            .cornerRadius(16)
    }


    func updateParticipantVideos(_ videos: [ParticipantVideoItem]) {
        print("[RemoteView.updateParticipant]")
        // 기존 목록에서 제거된 요소를 추려내어 구독해제 및 뷰 해제 처리를 진행
        let old = Set(self.currentVideos)
        let new = Set(videos)

        let detach = old.subtracting(new)
        let attach = new.subtracting(old)

        // 제거
        for item in detach {
            print("[RemoteView.updateParticipant] detach:\(item.pid)")
            renderer.detach(item: item)
            conference.unsubscribe(participantId: item.pid, videoId: item.vid)
        }

        // 신규 목록의 구독, 뷰 할당 진행
        for item in attach {
            print("[RemoteView.updateParticipant] attach:\(item.pid)")
            renderer.attach(item: item)
            conference.subscribe(participantId: item.pid, videoId: item.vid)

            if let view = renderer.getView(item: item) as? RenderView {
                conference.attach(participantId: item.pid, videoId: item.vid, renderView: view)
            }

        }
        self.currentVideos = videos
    }
}

struct RemoteGridView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteGridView(renderer: Renderer(),
                 conference: Conference())
    }
}
