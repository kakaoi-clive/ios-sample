//
//  RenderView.swift
//  conference
//

import Foundation
import SwiftUI
import ConnectLiveSDK


/// 로컬, 리모트뷰 표시를 위한 UIRenderView의 UIViewRepresentable 객체
///
struct RenderView: UIViewRepresentable, Hashable {
    public var uiView =  UIRenderView()
    public var id: String {
        uiView.uuid
    }

    /// 렌더뷰 초기화
    /// - Parameter contentMode: 컨텐츠 모드
    public init(contentMode: UIView.ContentMode) {
        uiView.videoContentMode = contentMode
    }


    public func makeUIView(context: Context) -> UIRenderView {
        return uiView
    }

    public func updateUIView(_ uiView: UIRenderView, context: Context) {
    }
}
