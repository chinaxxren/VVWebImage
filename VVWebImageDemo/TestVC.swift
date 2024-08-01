//
//  TestVC.swift
//  VVWebImageDemo
//

import UIKit
import VVWebImage

class TestVC: UIViewController {

    private var donwloader: VVMergeRequestImageDownloader!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.lightGray
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 100, width: view.frame.width - 20, height: view.frame.height - 200))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
        let url = URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/1.jpg")!
        let editor = vv_imageEditorCommon(with: imageView.frame.size,
                                          fillContentMode: .topLeft,
                                          maxResolution: 1024,
                                          corner: [.topLeft, .bottomRight],
                                          cornerRadius: 10,
                                          borderWidth: 2,
                                          borderColor: .yellow,
                                          backgroundColor: .blue)
        imageView.vv_setImage(with: url, placeholder: UIImage(named: "placeholder"), options: .none, editor: editor) { (image: UIImage?, data: Data?, error: Error?, cacheType: VVImageCacheType) in
            print("Completion")
            if let currentImage = image {
                print("Image: \(currentImage)")
                if let currentData = data {
                    print("Data: \(currentData)")
                } else {
                    print("No data")
                }
                print("Cache type: \(cacheType)")
                if let imageFormat = currentImage.vv_imageFormat {
                    print("Image format: \(imageFormat)")
                } else {
                    print("No image format")
                }
            } else if let currentError = error {
                print("Error: \(currentError)")
            }
        }
    }
}
