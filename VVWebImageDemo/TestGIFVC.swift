//
//  TestGIFVC.swift
//  VVWebImageDemo
//

import UIKit
import VVWebImage

class TestGIFVC: UIViewController {
    
    private var imageView: VVAnimatedImageView!
    private var scaleLabel: UILabel!
    
    private var editor: VVWebImageEditor?

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .lightGray
        
        let x: CGFloat = 10
        let width = view.frame.width - 20
        
        let scrollView = UIScrollView(frame: CGRect(x: x, y: 100, width: width, height: 200))
        scrollView.contentSize = CGSize(width: width + 20, height: 200)
        view.addSubview(scrollView)
        
        imageView = VVAnimatedImageView(frame: scrollView.bounds)
        imageView.backgroundColor = .yellow
        imageView.contentMode = .scaleAspectFit
        let url = Bundle(for: self.classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        imageView.image = VVAnimatedImage(vv_data: data)
        scrollView.addSubview(imageView)
        
        var y = scrollView.frame.maxY + 10
        let height: CGFloat = 30
        
        scaleLabel = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        scaleLabel.text = "Duration scale: 1.0"
        scaleLabel.textAlignment = .center
        view.addSubview(scaleLabel)
        
        y = scaleLabel.frame.maxY
        
        let scaleSilder = UISlider(frame: CGRect(x: x + 30, y: y, width: width - 60, height: height))
        scaleSilder.minimumValue = 0.2
        scaleSilder.maximumValue = 5
        scaleSilder.value = 1
        scaleSilder.addTarget(self, action: #selector(scaleSliderChanged(_:)), for: .valueChanged)
        view.addSubview(scaleSilder)
        
        y = scaleSilder.frame.maxY + 10
        
        var buttonIndex = 0
        let generateButton = { (title: String?, selectedTitle: String?) -> UIButton in
            let button = UIButton(frame: CGRect(x: x, y: y, width: self.imageView.frame.width, height: height))
            button.backgroundColor = (buttonIndex % 2 == 0 ? .blue : .red)
            button.setTitle(title, for: .normal)
            button.setTitle(selectedTitle, for: .selected)
            self.view.addSubview(button)
            y = button.frame.maxY
            buttonIndex += 1
            return button
        }
        
        let stopButton = generateButton("Stop", "Start")
        stopButton.addTarget(self, action: #selector(stopButtonClicked(_:)), for: .touchUpInside)
        
        let runLoopButton = generateButton("Change to default mode", "Change to common mode")
        runLoopButton.addTarget(self, action: #selector(runLoopButtonClicked(_:)), for: .touchUpInside)
        
        let filterButton = generateButton("Add filter", "Remove filter")
        filterButton.addTarget(self, action: #selector(filterButtonClicked(_:)), for: .touchUpInside)
        
        let frameIndexButton = generateButton("Set current frame index 0", nil)
        frameIndexButton.addTarget(self, action: #selector(frameIndexButtonClicked(_:)), for: .touchUpInside)
        
        let changeImageSegment = UISegmentedControl(frame: CGRect(x: x, y: y, width: width, height: height))
        changeImageSegment.insertSegment(withTitle: "GIF", at: 0, animated: false)
        changeImageSegment.insertSegment(withTitle: "Static", at: 1, animated: false)
        changeImageSegment.insertSegment(withTitle: "Images", at: 2, animated: false)
        changeImageSegment.selectedSegmentIndex = 0
        changeImageSegment.addTarget(self, action: #selector(changeImageSegmentChanged(_:)), for: .valueChanged)
        view.addSubview(changeImageSegment)
    }
    
    @objc private func scaleSliderChanged(_ slider: UISlider) {
        scaleLabel.text = String(format: "Duration scale: %.1f", slider.value)
        imageView.vv_animationDurationScale = Double(slider.value)
    }
    
    @objc private func stopButtonClicked(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
            imageView.stopAnimating()
        } else {
            imageView.startAnimating()
        }
    }
    
    @objc private func runLoopButtonClicked(_ button: UIButton) {
        button.isSelected = !button.isSelected
        imageView.vv_runLoopMode = (button.isSelected ? .default : .common)
    }
    
    @objc private func filterButtonClicked(_ button: UIButton) {
        if editor == nil {
            let e = vv_imageEditorCILookupTestFilter()
            editor = e
            button.isSelected = true
        } else {
            editor = nil
            button.isSelected = false
        }
        if let animatedImage = imageView.image as? VVAnimatedImage {
            animatedImage.vv_editor = editor
        }
    }
    
    @objc private func frameIndexButtonClicked(_ button: UIButton) {
        imageView.vv_setCurrentFrameIndex(0, decodeIfNeeded: true)
    }
    
    @objc private func changeImageSegmentChanged(_ segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            let url = Bundle(for: self.classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
            let data = try! Data(contentsOf: url)
            let animatedImage = VVAnimatedImage(vv_data: data)
            animatedImage?.vv_editor = editor
            imageView.image = animatedImage
            imageView.animationImages = nil
        case 1:
            imageView.image = UIImage(named: "placeholder")
            imageView.animationImages = nil
        case 2:
            imageView.animationImages = [UIImage(named: "sunflower.jpg")!, UIImage(named: "test_lookup")!]
            imageView.animationDuration = 1
            imageView.image = nil
        default:
            break
        }
    }
}
