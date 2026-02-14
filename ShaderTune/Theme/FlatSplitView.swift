import SwiftUI

/// A custom 3-pane horizontal split view using HSplitView with flat styling.
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
                    .background(AppTheme.bg)
            }

            content
                .frame(minWidth: 300, idealWidth: 500)
                .background(AppTheme.bg)

            detail
                .frame(minWidth: 200, idealWidth: 400)
                .background(AppTheme.bg)
        }
    }
}
