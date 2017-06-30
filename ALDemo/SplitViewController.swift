//
//  SplitViewController.swift
//  ALDemo
//
//  Created by 解 磊 on 2017/6/30.
//  Copyright © 2017年 AppLeg Corp. All rights reserved.
//

import UIKit

class SplitViewController: UIViewController {

    fileprivate let colors: [(name: String, value: UIColor)] = [
        ("Black", .black),
        ("Blue", .blue),
        ("Brown", .brown),
        ("Cyan", .cyan),
        ("DarkGray", .darkGray),
        ("gray", .gray),
        ("Green", .green),
        ("LightGray", .lightGray),
        ("Magenta", .magenta),
        ("Orange", .orange),
        ("Purple", .purple),
        ("Red", .red),
        ("White", .white),
        ("Yellow", .yellow)]
    
    private let splitVC = UISplitViewController()
    fileprivate var collapseDetailViewController = true
    fileprivate var showDetailSegue: UIStoryboardSegue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tableViewController = UITableViewController(style: .plain)
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        tableViewController.tableView.separatorStyle = .none
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        tableViewController.title = "Colors"
        let masterNC = UINavigationController()
        masterNC.addChildViewController(tableViewController)
        
        let viewController = UIViewController()
        viewController.title = "Color"
        viewController.navigationItem.leftBarButtonItem = self.splitVC.displayModeButtonItem
        viewController.navigationItem.leftItemsSupplementBackButton = true
        viewController.view.backgroundColor = nil
        let detailNC = UINavigationController(rootViewController: viewController)
        
        self.showDetailSegue = UIStoryboardSegue(identifier: "", source: tableViewController, destination: detailNC) {
            self.showDetailSegue.source.showDetailViewController(self.showDetailSegue.destination, sender: self)
        }
        
        self.splitVC.viewControllers = [masterNC, detailNC]
        self.splitVC.preferredDisplayMode = .allVisible
        self.splitVC.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.present(self.splitVC, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard self.showDetailSegue == segue,
            let source = segue.source as? UITableViewController,
            let selectedRow = source.tableView.indexPathForSelectedRow?.row
            else { return }
        segue.destination.childViewControllers.first?.title = self.colors[selectedRow].name
        segue.destination.childViewControllers.first?.view.backgroundColor = self.colors[selectedRow].value
    }
    
}

extension SplitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        cell.selectionStyle = .none
        let color = self.colors[indexPath.row]
        cell.textLabel?.text = color.name
        var rgb = [CGFloat](repeating: 0, count: 3)
        if color.value.getRed(&rgb[0], green: &rgb[1], blue: &rgb[2], alpha: nil) {
            rgb = rgb.map({ $0 < 0.5 ? 1 : 0 })
            let textColor = UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
            cell.textLabel?.textColor = textColor
        }
        cell.backgroundColor = color.value
        return cell
    }
}

extension SplitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.prepare(for: self.showDetailSegue, sender: self)
        self.showDetailSegue.perform()
    }
}

extension SplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return (secondaryViewController as? UINavigationController)?.topViewController?.view.backgroundColor == nil
    }
    
//    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
//    }
//    
//    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewControllerDisplayMode {
//        return .allVisible
//    }
//    
//    func splitViewControllerPreferredInterfaceOrientationForPresentation(_ splitViewController: UISplitViewController) -> UIInterfaceOrientation {
//        return .portrait
//    }
//    
//    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask {
//        return .all
//    }
//    
//    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
//        return nil
//    }
//    
//    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
//        return nil
//    }
//    
//    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
//        return nil
//    }
//    
//    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
//        return true
//    }
//    
//    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
//        return true
//    }
}
