import SwiftUI
import MapKit

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    @Binding var isSearching: Bool
    let onSelectLocation: (CLLocationCoordinate2D) -> Void

    @State private var showResults = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search location...", text: $searchText)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            searchResults = []
                            showResults = false
                        } else if newValue.count > 2 {
                            performSearch()
                        }
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        showResults = false
                        isFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)

            // Search results dropdown
            if showResults && !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults.prefix(6), id: \.self) { item in
                            Button(action: {
                                selectLocation(item)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)

                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if item != searchResults.last {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Search Methods

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            showResults = false
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let error = error {
                return
            }

            guard let response = response else {
                return
            }

            searchResults = response.mapItems
            showResults = !searchResults.isEmpty

        }
    }

    private func selectLocation(_ item: MKMapItem) {
        onSelectLocation(item.placemark.coordinate)
        searchText = item.name ?? ""
        showResults = false
        isFocused = false
        searchResults = []
    }
}
