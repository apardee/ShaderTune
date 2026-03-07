import SwiftUI

/// A custom 3-pane horizontal split view.
struct FlatSplitView<Sidebar: View, Content: View, Detail: View>: View {
    @Binding var showSidebar: Bool

    let sidebar: Sidebar
    let content: Content
    let detail: Detail

    init(
        showSidebar: Binding<Bool>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self._showSidebar = showSidebar
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
    }

    var body: some View {
        HSplitView {
            if showSidebar {
                sidebar
                    .frame(minWidth: 180, idealWidth: 220)
            }

            content
                .frame(minWidth: 300, idealWidth: 500)

            detail
                .frame(minWidth: 200, idealWidth: 400)
        }
    }
}
