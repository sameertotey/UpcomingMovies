//
//  SearchMoviesResultController.swift
//  UpcomingMovies
//
//  Created by Alonso on 11/7/18.
//  Copyright © 2018 Alonso. All rights reserved.
//

import UIKit

protocol SearchMoviesResultControllerDelegate: class {
    
    func searchMoviesResultController(_ searchMoviesResultController: SearchMoviesResultController, didSelectMovie movie: MovieDetailViewModel)
    
    func searchMoviesResultController(_ searchMoviesResultController: SearchMoviesResultController, didSelectRecentSearch searchText: String)
    
}

class SearchMoviesResultController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(MovieTableViewCell.self,
                           forCellReuseIdentifier: MovieTableViewCell.identifier)
        tableView.register(UINib(nibName: MovieTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: MovieTableViewCell.identifier)
        
        tableView.register(RecentSearchTableViewCell.self,
                           forCellReuseIdentifier: RecentSearchTableViewCell.identifier)
        tableView.register(UINib(nibName: RecentSearchTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: RecentSearchTableViewCell.identifier)
        
        return tableView
    }()
    
    private lazy var loadingFooterView: LoadingFooterView = {
        let footerView = LoadingFooterView()
        footerView.frame = LoadingFooterView.recommendedFrame
        footerView.startAnimating()
        return footerView
    }()
    
    private lazy var customFooterView: CustomFooterView = {
        let footerView = CustomFooterView()
        footerView.frame = CustomFooterView.recommendedFrame
        return footerView
    }()
    
    private var viewModel: SearchMoviesResultViewModel
    private var tableViewBottomConstraint: NSLayoutConstraint!
    
    weak var delegate: SearchMoviesResultControllerDelegate?
    
    // MARK: - Initializers
    
    init(viewModel: SearchMoviesResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        setupUI()
        setupBindables()
    }
    
    // MARK: - Private
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableViewBottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                                     tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     tableViewBottomConstraint])
    }
    
    private func configureFooterTableView(withState state: SearchMoviesResultViewModel.SearchMoviesResultViewState) {
        tableView.separatorStyle = .none
        switch state {
        case .empty:
            customFooterView.message = "No results to show."
            setupFooterTableView(tableView, withView: customFooterView, andFrame: CustomFooterView.recommendedFrame)
        case .populated, .initial:
            tableView.tableFooterView = UIView()
            tableView.separatorStyle = .singleLine
        case .searching:
            setupFooterTableView(tableView, withView: loadingFooterView, andFrame: LoadingFooterView.recommendedFrame)
        case .error(let error):
            customFooterView.message = error.localizedDescription
            setupFooterTableView(tableView, withView: customFooterView, andFrame: CustomFooterView.recommendedFrame)
        }
    }
    
    private func setupFooterTableView(_ tableView: UITableView, withView view: UIView, andFrame frame: CGRect) {
        let footerContainerView = UIView(frame: frame)
        footerContainerView.addSubview(view)
        tableView.tableFooterView = footerContainerView
    }
    
    // MARK: - Reactive Behaviour
    
    private func setupBindables() {
        viewModel.viewState.bindAndFire({ [weak self] state in
            guard let strongSelf = self else { return }
            strongSelf.tableView.reloadData()
            strongSelf.configureFooterTableView(withState: state)
        })
    }
    
    // MARK: - Public
    
    func startSearch(withSearchText searchText: String) {
        viewModel.clearMovies()
        viewModel.searchMovies(withSearchText: searchText)
    }
    
    func resetSearch() {
        viewModel.resetViewState()
    }
    
    // MARK: - Selectors
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard var keyboardFrame: CGRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        keyboardFrame = tableView.convert(keyboardFrame, from: nil)
        self.view.layoutIfNeeded()
        tableViewBottomConstraint.constant = -keyboardFrame.size.height + 50
        self.view.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.layoutIfNeeded()
        tableViewBottomConstraint.constant = 0
        self.view.layoutIfNeeded()
    }

}

// MARK: - UITableViewDataSource

extension SearchMoviesResultController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = viewModel.viewState.value.sections else { return 0 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = viewModel.viewState.value.sections?[section] else { return 0 }
        switch section {
        case .recentSearches:
            return viewModel.recentSearchCells.count
        case .searchedMovies:
            return viewModel.movieCells.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = viewModel.viewState.value.sections?[indexPath.section] else { return UITableViewCell() }
        switch section {
        case .recentSearches:
            return recentSearchesDataSource(tableView, indexPath: indexPath)
        case .searchedMovies:
            return searchedMoviesDataSource(tableView, indexPath: indexPath)
        }
    }
    
    fileprivate func recentSearchesDataSource(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentSearchTableViewCell.identifier, for: indexPath) as! RecentSearchTableViewCell
        cell.viewModel = viewModel.recentSearchCells[indexPath.row]
        return cell
    }
    
    fileprivate func searchedMoviesDataSource(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath) as! MovieTableViewCell
        cell.viewModel = viewModel.movieCells[indexPath.row]
        return cell
    }

}

// MARK: - UITableViewDelegate

extension SearchMoviesResultController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewState = viewModel.viewState.value
        switch viewState {
        case .initial:
            guard viewModel.recentSearchCells.count > 0 else { return }
            let searchText = viewModel.recentSearchCells[indexPath.row].searchText
            delegate?.searchMoviesResultController(self, didSelectRecentSearch: searchText)
        case .populated:
            guard let detailViewModel = viewModel.buildDetailViewModel(atIndex: indexPath.row) else {
                return
            }
            delegate?.searchMoviesResultController(self, didSelectMovie: detailViewModel)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let viewState = viewModel.viewState.value
        switch viewState {
        case .initial:
            return RecentSearchesHeaderView()
        case .populated:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        case .searching, .error, .empty:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let viewState = viewModel.viewState.value
        switch viewState {
        case .initial:
            return 50
        case .searching, .error, .empty, .populated:
            return 0
        }
    }
    
}