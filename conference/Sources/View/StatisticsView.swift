//
//  StatisticsView.swift
//  conference
//

import Foundation
import SwiftUI
import ConnectLiveSDK
import simd

struct StatisticsView: View {
    @ObservedObject var stats: Statistics
    @Binding var menuOpened: Bool
    private let width = UIScreen.main.bounds.width / 2

    var body: some View {
        HStack() {
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Statistics")
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

                getLogs()

            }
            .frame(width: self.width)
            .background(Color.gray)
            .cornerRadius(30, corners: [.topLeft, .bottomLeft])
            .shadow(color: Color.gray, radius: 12, x: 0, y: 5)
        }
        .transition(.move(edge: .trailing))
        .animation(.easeIn(duration: 0.25))
    }
    
    
    func getLogs() -> some View {
        var text: String = ""
        stats.report.forEach { stat in
            text.append(stat.log)
            text.append("\n\n")
        }
        
        return GeometryReader { geometry in
            ScrollView {
                Text("\(text)")
                    .padding(8)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(stats: Statistics(), menuOpened: .constant(true))
            .edgesIgnoringSafeArea(.all)
    }
}
