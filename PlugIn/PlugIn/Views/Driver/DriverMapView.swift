import SwiftUI
import MapKit

struct DriverMapView: View {
    @StateObject private var viewModel = DriverMapViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authService: AuthService
    @State private var sheetDragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // MARK: - Map
            Map(position: $viewModel.position, interactionModes: .all) {
                UserAnnotation()
                ForEach(viewModel.chargers) { charger in
                    Annotation("", coordinate: charger.coordinate) {
                        ChargerPinView(charger: charger) {
                            viewModel.selectCharger(charger)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // MARK: - Top Bar
            VStack {
                HStack {
                    SearchBar(
                        searchText: $viewModel.searchText,
                        searchResults: $viewModel.searchResults,
                        isSearching: $viewModel.isSearching,
                        onSelectLocation: { coordinate in
                            viewModel.centerOnLocation(coordinate)
                        }
                    )

                    // Filter button
                    Button(action: {
                        viewModel.showFilterSheet = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.hasActiveFilters ? .green : .primary)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)

                            // Active filter indicator
                            if viewModel.hasActiveFilters {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                    .offset(x: -2, y: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
            
            // MARK: - Center on User Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: viewModel.centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding()
                    .padding(.bottom, 16)
                }
            }
            .opacity(viewModel.showChargerDetail ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: viewModel.showChargerDetail)
            
            // MARK: - Loading
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            // MARK: - Charger Detail Bottom Sheet
            if viewModel.showChargerDetail, let charger = viewModel.selectedCharger {
                
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { dismissSheet() }
                    .gesture(DragGesture())
                    .transition(.opacity)
                
                // Sheet container
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Drag handle
                        Capsule()
                            .fill(Color(.systemGray3))
                            .frame(width: 36, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                        
                        ChargerDetailSheet(
                            charger: charger,
                            distance: viewModel.selectedChargerDistance,
                            onRequestCharge: {
                                dismissSheet()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    coordinator.push(.bookingRequest(charger))
                                }
                            },
                            onDismiss: { dismissSheet() }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
                    )
                    .offset(y: effectiveDragOffset)
                    .gesture(sheetDragGesture)
                    .onAppear { sheetDragOffset = 0 }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.showChargerDetail)
        .onAppear {
            viewModel.currentUserId = authService.currentUser?.id
        }
        .onChange(of: viewModel.showChargerDetail) { _, isPresented in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                coordinator.isChargerDetailSheetPresented = isPresented
            }
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Drag Helpers
    
    private var effectiveDragOffset: CGFloat {
        if sheetDragOffset < 0 {
            return sheetDragOffset * 0.15
        }
        return sheetDragOffset
    }
    
    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                sheetDragOffset = value.translation.height
            }
            .onEnded { value in
                let predictedEnd = value.predictedEndTranslation.height
                
                if value.translation.height > 100 || predictedEnd > 600 {
                    // Dismiss - transition handles the exit animation
                    dismissSheet()
                } else {
                    // Snap back to original position
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sheetDragOffset = 0
                    }
                }
            }
    }
    
    private func dismissSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.dismissChargerDetail()
        }
    }
}
