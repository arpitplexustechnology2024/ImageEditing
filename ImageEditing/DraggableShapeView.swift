//
//  DraggableShapeView.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import UIKit
import AVFoundation

// MARK: - DraggableShapeView
class DraggableShapeView: UIView {
    enum ShapeType: Int {
        case rectangle = 0
        case square = 1
        case circle = 2
        case triangle = 3
        case pentagon = 4
        case hexagon = 5
        case star = 6
        case oval = 9
    }
    
    let shapeType: ShapeType
    private var borderColor: UIColor
    private var initialFrame: CGRect = .zero
    private var lastLocation: CGPoint = .zero
    private var isResizing = false
    private let resizeHandleSize: CGFloat = 20
    private let borderWidth: CGFloat = 3.0
    
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
    
    var onDelete: (() -> Void)?
    
    init(frame: CGRect, type: ShapeType, color: UIColor) {
        self.shapeType = type
        self.borderColor = color
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
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
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
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
        guard !isResizing else { return }
        
        switch gesture.state {
        case .began:
            initialFrame = frame
            
        case .changed:
            var newFrame = initialFrame
            let scale = gesture.scale
            
            newFrame.size.width *= scale
            newFrame.size.height *= scale
            
            newFrame.size.width = max(50, newFrame.size.width)
            newFrame.size.height = max(50, newFrame.size.height)
            
            if shapeType == .square || shapeType == .circle {
                let size = max(newFrame.width, newFrame.height)
                newFrame.size = CGSize(width: size, height: size)
            }
            
            let centerX = initialFrame.midX
            let centerY = initialFrame.midY
            newFrame.origin.x = centerX - (newFrame.width / 2)
            newFrame.origin.y = centerY - (newFrame.height / 2)
            
            frame = newFrame
            
        case .ended, .cancelled:
            initialFrame = .zero
            
        default:
            break
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)
        context.setFillColor(UIColor.clear.cgColor)
        
        let drawRect = bounds.insetBy(dx: borderWidth/2, dy: borderWidth/2)
        
        switch shapeType {
        case .rectangle, .square:
            context.addRect(drawRect)
            context.drawPath(using: .stroke)
            
        case .circle:
            let path = UIBezierPath(ovalIn: drawRect)
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
            
        case .triangle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: drawRect.midX, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
            path.close()
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
            
        case .pentagon:
            let path = UIBezierPath()
            let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
            let radius = min(drawRect.width, drawRect.height) / 2
            let sides = 5
            
            for i in 0..<sides {
                let angle = CGFloat(i) * 2 * CGFloat.pi / CGFloat(sides) - CGFloat.pi / 2
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
            
        case .hexagon:
            let path = UIBezierPath()
            let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
            let radius = min(drawRect.width, drawRect.height) / 2
            let sides = 6
            
            for i in 0..<sides {
                let angle = CGFloat(i) * 2 * CGFloat.pi / CGFloat(sides) - CGFloat.pi / 6
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
            
        case .star:
            let path = UIBezierPath()
            let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
            let outerRadius = min(drawRect.width, drawRect.height) / 2
            let innerRadius = outerRadius * 0.4
            let points = 5
            
            for i in 0..<points * 2 {
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let angle = CGFloat(i) * CGFloat.pi / CGFloat(points) - CGFloat.pi / 2
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
        case .oval:
            let path = UIBezierPath(ovalIn: drawRect)
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
        }
    }
    
    func updateBorderColor(_ color: UIColor) {
        borderColor = color
        setNeedsDisplay()
    }
    
    deinit {
        deleteIndicator.removeFromSuperview()
    }
}
