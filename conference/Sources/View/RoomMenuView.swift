//
//  RoomMenuView.swift
//  conference
//

import Foundation
import SwiftUI
import CoreMedia

struct RoomMenuView: View {
    @ObservedObject var conference: Conference
    @Binding var menuOpened: Bool
    private let width = UIScreen.main.bounds.width - 90

    init(conference: Conference, menuOpened: Binding<Bool>) {
        print("[RoomMenuView.init] items:\(conference.participants.count)")
        self.conference = conference
        self._menuOpened = menuOpened
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Room Menu")
                    Spacer()
                    Button(action: {
                        self.menuOpened = false
                    }) {
                        Text("닫기")
                    }
                }
                .padding()
                .padding(.top, 50)

                Divider()


                Text("유저수: \(conference.participants.count)")
                    .padding()

                List {
                    ForEach(conference.participantIds, id:\.self) { id in
                        HStack {
                            if let item = conference.participants[id] {
                                ParticipantInfoView(participant: item)
                            }
                        }
                    }
                }
                .padding()

                Text("SDK version: \(conference.version)")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            }
            .frame(width: self.width)
            .background(Color.orange)
            .cornerRadius(30, corners: [.topRight, .bottomRight])
            .shadow(color: Color.gray, radius: 12, x: 0, y: 5)


            Spacer()
        }
        .transition(.move(edge: .leading))
        .animation(.easeIn(duration: 0.25))
    }
}

struct RoomMenuView_Previews: PreviewProvider {
    static var previews: some View {
        RoomMenuView(conference: Conference(), menuOpened: .constant(true))
            .edgesIgnoringSafeArea(.all)
    }
}
