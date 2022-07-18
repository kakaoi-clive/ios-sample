//
//  ParticipantInfoView.swift
//  conference
//

import Foundation
import SwiftUI

struct ParticipantInfoView: View {
    @ObservedObject var participant: ServiceParticipant


    init(participant: ServiceParticipant) {
        print("[ParticipantView.init]")
        self.participant = participant
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("ID: \(participant.id)")

                if participant.speaking {
                    Image("VoiceOn")
                }
            }

            HStack {
                Text("Media:")
                if participant.video {
                    Text("V")
                        .font(.system(size: 10))
                        .foregroundColor(Color.black)
                        .padding(2)
                        .background(Color.green)
                        .cornerRadius(5)
                }
                if participant.audio {
                    Text("A")
                        .font(.system(size: 10))
                        .foregroundColor(Color.black)
                        .padding(2)
                        .background(Color.green)
                        .cornerRadius(5)
                }
                if participant.screen {
                    Text("S")
                        .font(.system(size: 10))
                        .foregroundColor(Color.black)
                        .padding(2)
                        .background(Color.green)
                        .cornerRadius(5)
                }

                Text("level: \(participant.level)")
            }
        }
    }
}

struct ParticipantInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantInfoView(participant: ServiceParticipant(id: "11110000", audio: true, video: true))
            .edgesIgnoringSafeArea(.all)
    }
}
