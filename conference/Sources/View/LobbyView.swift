//
//  LobbyView.swift
//  conference
//

import Foundation
import SwiftUI
import AVFoundation



/// 로비 예시
///
/// 미리보기와 인증, 방 입장과 같은 처리를 위한 로비 예시입니다.
/// 카메라 권한과 마이크 권한은 info.plist 에 설정되어 있어야 합니다.
struct LobbyView: View, Equatable {
    var renderer: Renderer
    @ObservedObject var conference: Conference
    @Binding var currentView: CurrentView

    @StateObject private var provisioning = Provisioning()
    @State private var roomId: String = ""
    @State private var roomError: RoomError?
    @State private var menuOpened: Bool = false
    @State private var disabledButton: Bool = true

    private let camera: [AVCaptureDevice.Position] = [.front, .back]

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

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)

                Divider()

                // 로컬뷰
                renderer.localView
                    .frame(width: 180, height: 180, alignment: .center)
                    .padding(.top, 32)
                    .onAppear {
                        // 프리뷰를 위해 로컬 미디어를 생성하고, 뷰를 할당합니다.
                        print("[LobbyView] onAppear")
                        conference.createLocalMedia()
                        conference.media?.video.attach(renderer.localView.uiView)
                    }


                // 로컬 미디어 설정
                VStack(alignment: .leading) {
                    HStack {
                        Text("Camera")
                            .font( .system(size: 14))
                            .frame(width: 90, alignment: .leading)

                        Picker("position", selection: $conference.cameraPosition) {
                            ForEach(camera, id: \.self) {
                                if $0 == .front {
                                    Text("front")
                                } else {
                                    Text("back")
                                }
                            }
                        }
                        .pickerStyle(.segmented)


                        Toggle("", isOn: $conference.video)
                            .frame(width: 80)

                    }
                    .frame(height: 40)

                    HStack {
                        Text("Microphone")
                            .font( .system(size: 14))
                            .frame(width: 90, alignment: .leading)

                        Toggle("", isOn: $conference.audio)
                    }
                    .frame(height: 40)

                }
                .frame(width: 320)
                .padding(.top, 32)



                // 접속할 룸ID
                HStack {
                    Text("Room ID")
                        .font( .system(size: 15))
                        .frame(width: 90, alignment: .leading)

                    TextField("xxx-xxx-xxx", text: $roomId)
                        .lineLimit(1)
                        .font( .system(size: 15))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .valueChanged(value: roomId) { roomId in
                            if roomId.isEmpty {
                                disabledButton = true
                            } else {
                                disabledButton = false
                            }
                        }
    
                }
                .frame(width: 320, height: 40)
                .padding(.top, 16)


                // 연결 버튼
                HStack {
                    Button(action: {
                        // 인증과 룸 접속을 시도합니다.
                        print("[LobbyView] connect:\(roomId)")
                        disabledButton = true
                        Task {

                            // 인증
                            let result = await provisioning.signIn()
                            if let result = result {
                                roomError = result
                                disabledButton = false
                            } else {
                                roomError = nil

                                // 룸 접속
                                // 룸 id 제한( [0-9a-zA-Z-]{1,32} )
                                conference.connectRoom(roomId: roomId)
                            }
                        }
                    }) {
                        Text("Connect")
                            .foregroundColor(Color.black)
                            .frame(width: 200, height: 32, alignment: .center)
                            .background(Color(.systemYellow))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(disabledButton)
                    .onAppear {
                        self.disabledButton = false
                    }
                }
                .padding([.top, .bottom], 8)
                .valueChanged(value: conference.status) { status in
                    print("[LobbyView] status:\(status)")
                    if status == .connected {
                        currentView = .room
                    } else if status == .disconnected {
                        provisioning.signOut()
                    }
                }

                if conference.status == .connecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                }

                if !conference.errorMessage.isEmpty {
                    Text("error: \(conference.errorMessage)")
                }
                Spacer()

                Text("SDK version: \(conference.version)")
            }

            // 설정 메뉴
            if self.menuOpened {
                LobbyMenuView(provisioning: provisioning, menuOpened: $menuOpened)
                    .zIndex(10)
            }
        }
        .alert(item: $roomError) { error in
            print("[LobbyView] alert")
            return Alert(title: Text("인증 오류"), message: Text("\(error.message)"), dismissButton: .default(Text("확인")))
        }
    }


    static func == (lhs: LobbyView, rhs: LobbyView) -> Bool {
        return lhs.currentView == rhs.currentView
    }
}



struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView(renderer: Renderer(), conference: Conference(), currentView: .constant(.lobby))
    }
}
