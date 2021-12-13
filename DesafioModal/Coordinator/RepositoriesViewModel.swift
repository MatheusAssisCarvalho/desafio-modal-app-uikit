// RepositoriesViewModel.swift

import RxCocoa
import RxSwift

class RepositoriesViewModel {

    private let githubService: GithubService
    let filterService: FilterService

    let searchQuery = BehaviorSubject(value: "")
    var lastSearchQuery: String?
    var repositories: [Repository] = []
    var page = 1

    var hasScrollReachedBottom = false
    private var fetching = false

    let didSearchEnded = PublishSubject<Void>()
    let didRepositoryCellTapped = PublishSubject<Repository>()
    let didFilterSettingsButtonTapped = PublishSubject<Void>()

    let didViewUpdated = PublishSubject<Void>()

    init(githubService: GithubService) {
        self.githubService = githubService
        self.filterService = FilterService.shared
        search()
    }

    func search() {
        if fetching {
            return
        }

        guard var query = try? searchQuery.value() else {
            return
        }

        if query.isEmpty {
            query = "language:swift"
        }

        var newQuery = false

        if lastSearchQuery == nil || lastSearchQuery != query {
            lastSearchQuery = query
            newQuery = true
        }

        fetching = true

        githubService.searchRepositories(query: query, sorting: FilterService.shared.sorting, order: FilterService.shared.order, page: page) { [weak self] result in
            switch result {
            case .success(let response):
                if newQuery {
                    self?.repositories = response.repositories
                } else {
                    self?.repositories += response.repositories
                }
                self?.didSearchEnded.onNext(())

            default:
                self?.repositories += []

            }

            self?.fetching = false
        }
    }

    func showDetailsOfRepository(_ repository: Repository) {
        self.didRepositoryCellTapped.onNext(repository)
    }

    func showFilterSettings() {
        self.didFilterSettingsButtonTapped.onNext(())
    }

    func clearFilters() {
        FilterService.shared.reset()

        search()
    }

}
