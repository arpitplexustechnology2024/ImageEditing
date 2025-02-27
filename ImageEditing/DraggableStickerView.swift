//
//  DraggableStickerView.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import Foundation
import UIKit

// MARK: - Draggable Sticker View
class DraggableStickerView: UIView {
    private let imageView = UIImageView()
    
    private var initialCenter: CGPoint = .zero
    private var initialBounds: CGRect = .zero
    private var initialTransform: CGAffineTransform = .identity
    
    private var originalPosition: CGPoint?
    private var deleteAreaFrame: CGRect?
    private let deleteIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        view.layer.cornerRadius = 10
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "trash.fill"))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()
    
    var onDelete: (() -> Void)?
    
    init(image: UIImage) {
        super.init(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        setup(with: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(with image: UIImage) {
        backgroundColor = .clear

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = bounds.insetBy(dx: 15, dy: 15)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        
        if let parentView = UIApplication.shared.keyWindow {
            parentView.addSubview(deleteIndicator)
            
            deleteIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                deleteIndicator.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
                deleteIndicator.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -20),
                deleteIndicator.widthAnchor.constraint(equalToConstant: 200),
                deleteIndicator.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            deleteAreaFrame = CGRect(
                x: parentView.bounds.width / 2 - 100,
                y: parentView.bounds.height - 70,
                width: 200,
                height: 50
            )
        }

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:)))
        addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
        addGestureRecognizer(pinchGesture)

        panGesture.delegate = self
        pinchGesture.delegate = self
    }
    
    // MARK: - Gesture Handlers
    @objc private func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        
        switch gesture.state {
        case .began:
            initialCenter = center
            originalPosition = center
            deleteIndicator.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.deleteIndicator.alpha = 1.0
            }
            
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            
            if let deleteArea = deleteAreaFrame, frame.intersects(deleteArea) {
                UIView.animate(withDuration: 0.2) {
                    self.deleteIndicator.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    self.deleteIndicator.backgroundColor = UIColor.red.withAlphaComponent(0.8)
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.deleteIndicator.transform = .identity
                    self.deleteIndicator.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                }
            }
            
        case .ended, .cancelled:
            if let deleteArea = deleteAreaFrame, frame.intersects(deleteArea) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.alpha = 0
                    self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    self.deleteIndicator.isHidden = true
                }) { _ in
                    self.onDelete?()
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.deleteIndicator.alpha = 0
                } completion: { _ in
                    self.deleteIndicator.isHidden = true
                }
            }
            
        default:
            break
        }
    }
    
    @objc private func pinchGestureHandler(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialBounds = bounds
            initialTransform = transform
        case .changed:
            transform = initialTransform.scaledBy(x: gesture.scale, y: gesture.scale)
        default:
            break
        }
    }
    
    @objc private func rotateGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let touchPoint = gesture.location(in: superview)
        let center = self.center
        
        switch gesture.state {
        case .changed:
            let dx = touchPoint.x - center.x
            let dy = touchPoint.y - center.y
            let angle = atan2(dy, dx)

            transform = CGAffineTransform(rotationAngle: angle - .pi/2)
        default:
            break
        }
    }
    
    deinit {
        deleteIndicator.removeFromSuperview()
    }
}

extension DraggableStickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
