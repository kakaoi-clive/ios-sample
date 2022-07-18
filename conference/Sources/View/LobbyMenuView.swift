//
//  LobbyMenuView.swift
//  conference
//

import Foundation
import SwiftUI

struct LobbyMenuView: View {
    @ObservedObject var provisioning: Provisioning
    @Binding var menuOpened: Bool

    private let width = UIScreen.main.bounds.width - 90

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Text("Lobby Menu")
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


                ScrollView {
                    preferenceViews()
                }
            }
            .frame(width: self.width)
            .padding()
            .background(Color.orange)

            Spacer()
        }
        .transition(.move(edge: .leading))
        .animation(.easeIn(duration: 0.25))
    }

    @ViewBuilder
    func preferenceViews() -> some View {
        VStack {
            Text("Provision")
                .bold()

            /// 각 설정 입력
            VStack(alignment: .leading) {
                makePreferenceView(name: "Service ID", bind: $provisioning.serviceId)
                makePreferenceView(name: "Service Secret", bind: $provisioning.serviceSecret)
                makePreferenceView(name: "External Token", bind: $provisioning.externalToken)
            }

            Text("Server")
                .bold()
                .padding(.top , 32)

            VStack(alignment: .leading) {
                makePreferenceView(name: "Provisioning", bind: $provisioning.provisioningEndpoint)
                makePreferenceView(name: "API", bind: $provisioning.apiServer)
                makePreferenceView(name: "TURN", bind: $provisioning.turnServer)
                makePreferenceView(name: "TURN username", bind: $provisioning.turnServer)
                makePreferenceView(name: "TURN credential", bind: $provisioning.turnServer)
            }
        }
    }

    @ViewBuilder
    func makePreferenceView(name: String, bind: Binding<String>) -> some View {
        HStack {
            Text(name)
                .font( .system(size: 12))
                .frame(width: UIScreen.main.bounds.width * 0.2, alignment: .leading)

            TextField(name, text: bind)
                .lineLimit(1)
                .font( .system(size: 12))
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
        }
        .frame(height: 30)
    }
}

struct LobbyMenuView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyMenuView(provisioning: Provisioning(), menuOpened: .constant(true))
            .edgesIgnoringSafeArea(.all)
    }
}
