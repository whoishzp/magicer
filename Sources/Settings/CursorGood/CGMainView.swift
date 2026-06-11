import SwiftUI

struct CGMainView: View {
    var body: some View {
        HSplitView {
            CGSessionListView()
                .frame(minWidth: 180, maxWidth: 260)
            CGChatView()
                .frame(minWidth: 400)
        }
        .frame(minWidth: 620, minHeight: 400)
    }
}
