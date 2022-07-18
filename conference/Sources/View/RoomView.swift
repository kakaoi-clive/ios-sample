//
//  RoomView.swift
//  conference
//

import Foundation
import SwiftUI
import ConnectLiveSDK


struct RoomView: View {
    var renderer: Renderer
    @ObservedObject var conference: Conference
    @Binding var currentView: CurrentView

    @State private var menuOpened: Bool = false
    @State private var statsOpened: Bool = false
    @State private var page: Int = 0
    @State private var message: String = ""

    init(renderer: Renderer, conference: Conference, currentView: Binding<CurrentView>) {
        print("[RoomView.init]")
        self.renderer = renderer
        self.conference = conference
        self._currentView = currentView
    }

    var body: some View {
        ZStack {
            VStack {
                // 타이틀 영역
                HStack {
                    // 메뉴
                    Button(action: {
                        menuOpened = true
                    }) {
                        Text("menu")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black)
                            .padding(5)
                            .background(Color.yellow)
                            .cornerRadius(5)

                    }

                    Text("iCL2.0 Conference Sample")
                        .font(.system(size: 20))
                        .bold()

                    Spacer()

                    Button(action: {
                        statsOpened = true
                    }) {
                        Text("log")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black)
                            .padding(5)
                            .background(Color.yellow)
                            .cornerRadius(5)

                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)

                Divider()

                HStack {
                    Button(action: {
                        conference.leave()
                    }) {
                        Text("로비로 나가기")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black)
                            .padding(5)
                            .background(Color.yellow)
                            .cornerRadius(5)
                    }
                    .valueChanged(value: conference.status) { status in
                        if status == .disconnected {
                            ConnectLive.signOut()
                            currentView = .lobby
                        }
                    }


                    if conference.screenShareStatus == .notAvailable || conference.screenShareStatus == .broadcastClosed {
                        Button(action: {
                            conference.startScreenSharing()
                        }) {
                            Text("화면공유 시작")
                                .font(.system(size: 14))
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    } else {
                        Button(action: {
                            conference.stopScreensharing()
                        }) {
                            Text("화면공유 중지")
                                .font(.system(size: 14))
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.green)
                                .cornerRadius(5)
                        }
                    }
                }
                VStack(spacing: 8) {
                    ScrollView {
                        RemoteGridView(renderer: renderer, conference: conference)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 32)

                }

                Spacer()

                Divider()
                VStack(alignment: .leading) {
                    HStack {
                        Text("수신 메시지")
                            .font(.system(size: 14))
                            .frame(width: 80)

                        Text("\(conference.receivedMessage)")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }


                    HStack {
                        Text("메시지 전송")
                            .font(.system(size: 14))
                            .frame(width: 80)

                        TextField("Message", text: $message, onCommit: {
                            conference.sendMessage(participantIds: [], message: message)
                            message = ""
                        })
                            .lineLimit(1)
                            .font( .system(size: 12))
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)

                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, 8)

                Divider()
                VStack(spacing: 8) {
                    LocalView(renderer: renderer, conference: conference)
                        .padding(8)
                }
            }

            if self.menuOpened {
                RoomMenuView(conference: conference, menuOpened: $menuOpened)
                    .zIndex(99)
            }


            if self.statsOpened {
                StatisticsView(stats: conference.statistics, menuOpened: $statsOpened)
                    .zIndex(98)
            }
        }
    }

    static func == (lhs: RoomView, rhs: RoomView) -> Bool {
        return lhs.currentView == rhs.currentView
    }
}




struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        RoomView(renderer: Renderer(),
                 conference: Conference(),
                 currentView: .constant(.room))
    }
}

