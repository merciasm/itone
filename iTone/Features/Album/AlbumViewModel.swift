//
//  AlbumViewModel.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Album ViewModel
@MainActor
@Observable
final class AlbumViewModel {
    var album: Album?
    var viewState: ViewState = .loading

    private let collectionId: Int
    private let repository: SongRepositoryProtocol

    init(collectionId: Int, repository: SongRepositoryProtocol) {
        self.collectionId = collectionId
        self.repository = repository
    }

    func load() async {
        if case .loaded = viewState { return }
        if case .empty = viewState { return }
        viewState = .loading
        do {
            album = try await repository.getAlbumSongs(collectionId: collectionId)
            viewState = album?.songs.isEmpty == true ? .empty : .loaded
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
}
