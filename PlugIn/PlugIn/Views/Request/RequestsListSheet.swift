import SwiftUI

struct RequestsListSheet: View {
    @StateObject private var viewModel = RequestViewModel()
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        RequestsListView(viewModel: viewModel)
            .environmentObject(coordinator)
    }
}
