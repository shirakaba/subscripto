//
//  SectionUI.swift
//  pinyinjector
//
//  Created by jamie on 28/08/2017.
//  Copyright © 2017 Jamie Birch. All rights reserved.
//

import Foundation
import UIKit

class SectionUI {
    static func setUp(_ slider: UISlider, minimumValue: Float, maximumValue: Float, startValue: Float, isContinuous: Bool, target: Any?, selector: Selector) -> Void {
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.isContinuous = isContinuous
        slider.value = startValue
        slider.addTarget(target, action: selector, for: .valueChanged)
    }
    
    static func setUp(_ picker: UIPickerView, startingRowIndex: Int, delegate: UIPickerViewDelegate, dataSource: UIPickerViewDataSource) -> Void {
        picker.delegate = delegate // UIPickerViewDelegate
        picker.dataSource = dataSource // UIPickerViewDataSource
        picker.backgroundColor = UIColor.white
        picker.selectRow(startingRowIndex, inComponent: 0, animated: false)
    }
    
    static func setUp(staticLabel: UILabel, staticText: String, dynamicLabel: UILabel, dynamicText: String) -> Void {
        staticLabel.text = staticText
        dynamicLabel.text = dynamicText
        dynamicLabel.textColor = UIColor.lightGray
    }
    
    static func setUp(sectionTitle label: UILabel, text: String, subSection: Bool = false) -> UILabel {
        label.text = subSection ? text.uppercased() : text
        label.textAlignment = subSection ? .left : .center
        if(subSection){ label.textColor = UIColor.gray; }
        label.font = UIFont.boldSystemFont(ofSize: subSection ? UILabel().font.pointSize * 0.75 : UILabel().font.pointSize)
        return label
    }

    static func setUp(sectionExplanation label: UILabel, text: String) -> UILabel {
        label.text = text
        // label.textAlignment = .center
        label.textColor = UIColor.gray
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: UILabel().font.pointSize * 0.75)
        return label
    }
    
    static func initImgView(named: String) -> UIImageView {
        let iv: UIImageView = UIImageView(image: UIImage(named: named)!.withRenderingMode(.alwaysOriginal))
        iv.contentMode = .scaleAspectFit
        return iv
    }

    static func initButton(tagged tag: Int, target: Any?, selector: Selector, backgroundColor: UIColor? = nil) -> UIButton {
        let button = UIButton()
        button.addTarget(target, action: selector, for: .touchUpInside)
        button.tag = tag
        button.showsTouchWhenHighlighted = true

        if let bg = backgroundColor { button.backgroundColor = bg; }
        return button
    }

    /** https://www.raywenderlich.com/160646/uistackview-tutorial-introducing-stack-views-2 */
    static func initSection(axis: UILayoutConstraintAxis = .vertical, alignment: UIStackViewAlignment = .fill, distribution: UIStackViewDistribution = .fill, spacing: CGFloat = 8.0, backgroundColor: UIColor? = nil, margins: UIEdgeInsets? = nil) -> UIStackView {
        var stack: UIStackView
        if let bg = backgroundColor {
            stack = StackViewWithBG()
            stack.backgroundColor = bg
        } else {
            stack = UIStackView()
        }
        if let layoutMargins = margins {
            stack.layoutMargins = layoutMargins
            stack.isLayoutMarginsRelativeArrangement = true
        }
        stack.axis = axis
        stack.alignment = alignment
        stack.distribution = distribution
        stack.spacing = spacing
        return stack
    }

    /** Top and bottom margins are left unset, as spacing is expected to handle it */
    static func initTextRow(label: UILabel, margins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)) -> UIStackView {
        let row: UIStackView = initSection(axis: .horizontal, margins: margins)
        row.addArrangedSubview(label)
        return row
    }


    static func constrain(_ view: UIView, _ vd: [String : Any], H: [String], V: [String]){
        SectionUI.constrainOne(view, on: "H", with: H, using: vd)
        SectionUI.constrainOne(view, on: "V", with: V, using: vd)
    }
    
    static func constrainOne(_ view: UIView, on axis: String, with visualConstraints: [String], using vd: [String : Any]) -> Void {
        visualConstraints.forEach { view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: axis + ":|" + $0 + "|", options: [], metrics: nil, views: vd))}
    }
    
    /** https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift */
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
