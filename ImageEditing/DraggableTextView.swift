//
//  DraggableTextView.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import UIKit
import AVFoundation

// MARK: - UPDATED DraggableTextView with improved resizing
class DraggableTextView: UIView {
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        return label
    }()
    
    var onDelete: (() -> Void)?
    
    private var originalPosition: CGPoint?
    private var deleteAreaFrame: CGRect?
    private let deleteAreaHeight: CGFloat = 60
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
    
    private var initialFontSize: CGFloat = 17.0
    private var initialBounds: CGRect?
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    init(text: String, textColor: UIColor, font: UIFont) {
        super.init(frame: .zero)
        setupView(with: text, textColor: textColor, font: font)
        initialFontSize = font.pointSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(with text: String, textColor: UIColor, font: UIFont) {
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 5
        
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
        
        addSubview(textLabel)
        
        textLabel.text = text
        textLabel.textColor = textColor
        textLabel.font = font
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        
        let size = text.size(withAttributes: [.font: font])
        frame.size = CGSize(width: size.width + 40, height: size.height + 40)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        
        switch gesture.state {
        case .began:
            originalPosition = center
            deleteIndicator.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.deleteIndicator.alpha = 1.0
            }
            
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            
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

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialBounds = bounds
            
        case .changed:
            let currentScale = gesture.scale
            let newFontSize = initialFontSize * currentScale
            
            let clampedFontSize = min(max(newFontSize, initialFontSize * minScale), initialFontSize * maxScale)
            
            if let currentFont = textLabel.font {
                
                let newFont = UIFont(descriptor: currentFont.fontDescriptor, size: clampedFontSize)
                textLabel.font = newFont
                
                let newSize = textLabel.text?.size(withAttributes: [.font: newFont]) ?? .zero
                bounds.size = CGSize(width: newSize.width + 40, height: newSize.height + 40)
            }
            
        case .ended, .cancelled:
            if let currentFont = textLabel.font {
                initialFontSize = currentFont.pointSize
            }
            
        default:
            break
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {

        UIView.animate(withDuration: 0.2, animations: {
            self.layer.borderColor = UIColor.yellow.cgColor
            self.layer.borderWidth = 2
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.3, options: [], animations: {
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 1
            }, completion: nil)
        }
    }
    
    func updateText(_ newText: String) {
        textLabel.text = newText
        
        if let font = textLabel.font {
            let size = newText.size(withAttributes: [.font: font])
            frame.size = CGSize(width: size.width + 40, height: size.height + 40)
        }
    }
    
    deinit {
        deleteIndicator.removeFromSuperview()
    }
}
