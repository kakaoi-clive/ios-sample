//
//  ContentView.swift
//  conference
//

import SwiftUI

enum CurrentView: Equatable {
    case lobby
    case room
}

struct ContentView: View {
    var renderer: Renderer
    var conference: Conference

    @State private var currentView: CurrentView = .lobby

    var body: some View {
        switch currentView {
        case .lobby:
            LobbyView(renderer: renderer, conference: conference, currentView: $currentView)
        case .room:
            RoomView(renderer: renderer, conference: conference, currentView: $currentView)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(renderer: Renderer(), conference: Conference())
    }
}
