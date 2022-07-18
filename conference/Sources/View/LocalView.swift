//
//  LocalView.swift
//  conference
//

import AVFoundation
import SwiftUI

struct LocalView: View {
    var renderer: Renderer
    @ObservedObject var conference: Conference

    private let camera: [AVCaptureDevice.Position] = [.front, .back]

    var body: some View {
        HStack {
            renderer.localView
                .frame(width: 120, height: 120, alignment: .center)
                .cornerRadius(16)
                .onAppear {
                    conference.media?.video.attach(renderer.localView.uiView)
                }

            VStack(alignment: .leading) {
                Text("Participant ID: \(conference.myId)")
                    .font( .system(size: 14))
                
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
        }
    }
}

struct LocalView_Previews: PreviewProvider {
    static var previews: some View {
        LocalView(renderer: Renderer(),
                 conference: Conference())
    }
}
