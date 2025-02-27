//
//  Extension.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import Foundation
import UIKit

// MARK: - Swizzle method implementation
extension UIViewController {
    static func swizzleMethods() {
        guard let originalMethod = class_getInstanceMethod(ImageEditingVC.self, #selector(ImageEditingVC.ShapeButtonTapped(_:))),
              let swizzledMethod = class_getInstanceMethod(ImageEditingVC.self, #selector(ImageEditingVC.ShapeButtonTapped(_:))) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        guard let originalSaveMethod = class_getInstanceMethod(ImageEditingVC.self, #selector(ImageEditingVC.saveButtonTapped(_:))),
              let swizzledSaveMethod = class_getInstanceMethod(ImageEditingVC.self, #selector(ImageEditingVC.ShapeButtonTapped(_:))) else {
            return
        }
        
        method_exchangeImplementations(originalSaveMethod, swizzledSaveMethod)
    }
}


// MARK: - Associated Keys for object association
struct AssociatedKeys {
    static var shapeViewsKey = "ImageEditingVC.shapeViewsKey"
    static var stickerViewsKey = "ImageEditingVC.stickerViewsKey"
}

