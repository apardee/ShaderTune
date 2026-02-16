import SwiftUI

/// A custom 3-pane horizontal split view with an optional bottom pane.
struct FlatSplitViewWithBottom<Sidebar: View, Content: View, Detail: View, Bottom: View>: View {
    @Binding var showSidebar: Bool
    @Binding var showBottom: Bool

    let sidebar: Sidebar
    let content: Content
    let detail: Detail
    let bottom: Bottom

    init(
        showSidebar: Binding<Bool>,
        showBottom: Binding<Bool>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self._showSidebar = showSidebar
        self._showBottom = showBottom
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.bottom = bottom()
    }

    var body: some View {
        VSplitView {
            // Top section: horizontal split
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
            .frame(minHeight: 300)

            // Bottom pane
            if showBottom {
                bottom
                    .frame(minHeight: 100, idealHeight: 200, maxHeight: 400)
                    .background(AppTheme.bg)
            }
        }
    }
}
