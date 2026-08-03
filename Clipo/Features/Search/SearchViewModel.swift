import Foundation

/// Search state holder. The current UI binds `HistoryViewModel.searchText` directly;
/// this exists as a seam for future dedicated search screens (see PRD roadmap).
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
}
