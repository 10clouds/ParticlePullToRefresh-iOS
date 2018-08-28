//
//  ViewController.swift
//  Example
//
//  Created by Alex Demchenko on 27/08/2018.
//  Copyright © 2018 10Clouds. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addParticlePullToRefresh(color: .yellow) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.tableView.particlePullToRefresh?.endRefreshing()
            }
        }
    }

    deinit {
        tableView.removeParticlePullToRefresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 24
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        cell.textLabel?.text = "Row \(indexPath.row)"
        cell.backgroundColor = .clear

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
