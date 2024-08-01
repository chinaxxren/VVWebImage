//
//  TestFilterVC.swift
//  VVWebImageDemo
//

import UIKit
import VVWebImage

class TestFilterVC: UIViewController {

    private var imageView: UIImageView!
    private var button: UIButton!
    private var filtered: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        imageView = UIImageView(frame: CGRect(x: 10, y: 100, width: view.bounds.width - 20, height: view.bounds.height - 200))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "sunflower.jpg")
        view.addSubview(imageView)
        
        button = UIButton(frame: CGRect(x: 10, y: imageView.frame.maxY + 10, width: imageView.frame.width, height: 30))
        button.backgroundColor = .blue
        button.setTitle("Add filter", for: .normal)
        button.setTitle("Reset", for: .selected)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc private func clickButton() {
        filtered = !filtered
        if filtered {
            let editor = vv_imageEditorCILookupTestFilter()
            imageView.image = editor.edit(imageView.image!)
        } else {
            imageView.image = UIImage(named: "sunflower.jpg")
        }
        button.isSelected = filtered
    }
}
