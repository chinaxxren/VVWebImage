//
//  MainMenuVC.swift
//  VVWebImageDemo
//

import UIKit
import VVWebImage

class MainMenuVC: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    private var list: [(String, () -> Void)]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let test = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(TestVC(), animated: true) }
        }
        let filter = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(TestFilterVC(), animated: true) }
        }
        let gif = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(TestGIFVC(), animated: true) }
        }
        let imageWall = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(ImageWallVC(), animated: true) }
        }
        let gifWall = { [weak self] in
            if let self = self { self.navigationController?.pushViewController(GIFWallVC(), animated: true) }
        }
        let clearCache = { [weak self] in
            if self != nil { VVWebImageManager.shared.imageCache.clear(.all, completion: nil) }
        }
        list = [("Test", test),
                ("Test filter", filter),
                ("Test GIF", gif),
                ("Image wall", imageWall),
                ("GIF wall", gifWall),
                ("Clear cache", clearCache)]
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension MainMenuVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        cell.textLabel?.text = list[indexPath.row].0
        return cell
    }
}

extension MainMenuVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        list[indexPath.row].1()
    }
}
