import SwiftUI

/// A custom 2-pane horizontal split view with an optional bottom pane.
struct FlatSplitViewWithBottom<Sidebar: View, Content: View, Bottom: View>: View {
    @Binding var showSidebar: Bool
    @Binding var showBottom: Bool

    let sidebar: Sidebar
    let content: Content
    let bottom: Bottom

    init(
        showSidebar: Binding<Bool>,
        showBottom: Binding<Bool>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self._showSidebar = showSidebar
        self._showBottom = showBottom
        self.sidebar = sidebar()
        self.content = content()
        self.bottom = bottom()
    }

    var body: some View {
        VSplitView {
            // Top section: horizontal split
            HSplitView {
                if showSidebar {
                    sidebar
                        .frame(minWidth: 180, idealWidth: 220)
                }

                content
                    .frame(minWidth: 300)
            }
            .frame(minHeight: 300)

            // Bottom pane
            if showBottom {
                bottom
                    .frame(minHeight: 100, idealHeight: 200, maxHeight: 400)
            }
        }
    }
}
