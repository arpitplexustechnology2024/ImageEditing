//
//  ShapePickerView.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import Foundation
import UIKit

// MARK: - ShapePickerView
class ShapePickerView: UIView {
    private let backgroundView = UIView()
    private let stackView = UIStackView()
    private let shapesStackView = UIStackView()
    private let doneButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let colorButton = UIButton(type: .system)
    
    private let rectangleButton = UIButton()
    private let squareButton = UIButton()
    private let circleButton = UIButton()
    private let triangleButton = UIButton()
    
    private let pentagonButton = UIButton()
    private let hexagonButton = UIButton()
    private let starButton = UIButton()
    private let ovalButton = UIButton()
    
    private var selectedColor: UIColor = .white
    private var selectedShape: DraggableShapeView.ShapeType = .rectangle
    
    var onCancel: (() -> Void)?
    var onAddShape: ((DraggableShapeView.ShapeType, UIColor) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundView.backgroundColor = .lightGray
        backgroundView.layer.cornerRadius = 12
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.3
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 5
        
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.addSubview(stackView)
        
        let allShapesStackView = UIStackView()
        allShapesStackView.axis = .vertical
        allShapesStackView.spacing = 10
        allShapesStackView.alignment = .fill
        allShapesStackView.distribution = .fillEqually
        
        let shapesRow1 = UIStackView()
        shapesRow1.axis = .horizontal
        shapesRow1.spacing = 10
        shapesRow1.alignment = .fill
        shapesRow1.distribution = .fillEqually
        
        let shapesRow2 = UIStackView()
        shapesRow2.axis = .horizontal
        shapesRow2.spacing = 10
        shapesRow2.alignment = .fill
        shapesRow2.distribution = .fillEqually
        
        setupShapeButton(rectangleButton, shape: .rectangle, color: .clear)
        setupShapeButton(squareButton, shape: .square, color: .clear)
        setupShapeButton(circleButton, shape: .circle, color: .clear)
        setupShapeButton(triangleButton, shape: .triangle, color: .clear)
        
        setupShapeButton(pentagonButton, shape: .pentagon, color: .clear)
        setupShapeButton(hexagonButton, shape: .hexagon, color: .clear)
        setupShapeButton(starButton, shape: .star, color: .clear)
        setupShapeButton(ovalButton, shape: .oval, color: .clear)
        
        colorButton.backgroundColor = .gray
        colorButton.setTitle("Select color", for: .normal)
        colorButton.setTitleColor(.white, for: .normal)
        colorButton.layer.cornerRadius = 8
        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
        
        shapesRow1.addArrangedSubview(rectangleButton)
        shapesRow1.addArrangedSubview(squareButton)
        shapesRow1.addArrangedSubview(circleButton)
        shapesRow1.addArrangedSubview(triangleButton)
        
        shapesRow2.addArrangedSubview(pentagonButton)
        shapesRow2.addArrangedSubview(hexagonButton)
        shapesRow2.addArrangedSubview(starButton)
        shapesRow2.addArrangedSubview(ovalButton)
        
        allShapesStackView.addArrangedSubview(shapesRow1)
        allShapesStackView.addArrangedSubview(shapesRow2)
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        doneButton.setTitle("Add Shape", for: .normal)
        doneButton.backgroundColor = .systemBlue
        doneButton.tintColor = .white
        doneButton.layer.cornerRadius = 8
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(doneButton)
        
        stackView.addArrangedSubview(allShapesStackView)
        stackView.addArrangedSubview(colorButton)
        stackView.addArrangedSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundView.heightAnchor.constraint(equalToConstant: 250),
            
            stackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -16)
        ])
        
        updateSelectedShape(.rectangle)
        updateShapeColors()
    }
    
    private func setupShapeButton(_ button: UIButton, shape: DraggableShapeView.ShapeType, color: UIColor) {
        button.backgroundColor = .clear
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0
        button.layer.masksToBounds = true
        
        let shapeView = UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
        shapeView.backgroundColor = .clear
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.tag = 100
        shapeView.isUserInteractionEnabled = false
        
        button.addSubview(shapeView)
        
        NSLayoutConstraint.activate([
            shapeView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            shapeView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            shapeView.widthAnchor.constraint(equalToConstant: 40),
            shapeView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        let borderColor = UIColor.black.cgColor
        let borderWidth: CGFloat = 2.0

        switch shape {
        case .rectangle:
            shapeView.layer.cornerRadius = 0
            shapeView.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            shapeView.layer.borderColor = borderColor
            shapeView.layer.borderWidth = borderWidth
            NSLayoutConstraint.activate([
                shapeView.widthAnchor.constraint(equalToConstant: 40),
                shapeView.heightAnchor.constraint(equalToConstant: 30)
            ])
            
        case .square:
            shapeView.layer.cornerRadius = 0
            shapeView.layer.borderColor = borderColor
            shapeView.layer.borderWidth = borderWidth
            
        case .circle:
            shapeView.layer.cornerRadius = 20
            shapeView.layer.borderColor = borderColor
            shapeView.layer.borderWidth = borderWidth
            
        case .triangle:
            let triangleLayer = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 20, y: 0))
            path.addLine(to: CGPoint(x: 40, y: 40))
            path.addLine(to: CGPoint(x: 0, y: 40))
            path.close()
            
            triangleLayer.path = path.cgPath
            triangleLayer.strokeColor = borderColor
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.lineWidth = borderWidth
            
            shapeView.layer.addSublayer(triangleLayer)
            
        case .pentagon:
            let pentagonLayer = CAShapeLayer()
            let path = UIBezierPath()
            let center = CGPoint(x: 20, y: 20)
            let radius: CGFloat = 20
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
            
            pentagonLayer.path = path.cgPath
            pentagonLayer.strokeColor = borderColor
            pentagonLayer.fillColor = UIColor.clear.cgColor
            pentagonLayer.lineWidth = borderWidth
            
            shapeView.layer.addSublayer(pentagonLayer)
            
        case .hexagon:
            let hexagonLayer = CAShapeLayer()
            let path = UIBezierPath()
            let center = CGPoint(x: 20, y: 20)
            let radius: CGFloat = 20
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
            
            hexagonLayer.path = path.cgPath
            hexagonLayer.strokeColor = borderColor
            hexagonLayer.fillColor = UIColor.clear.cgColor
            hexagonLayer.lineWidth = borderWidth
            
            shapeView.layer.addSublayer(hexagonLayer)
            
        case .star:
            let starLayer = CAShapeLayer()
            let path = UIBezierPath()
            let center = CGPoint(x: 20, y: 20)
            let outerRadius: CGFloat = 20
            let innerRadius: CGFloat = 10
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
            
            starLayer.path = path.cgPath
            starLayer.strokeColor = borderColor
            starLayer.fillColor = UIColor.clear.cgColor
            starLayer.lineWidth = borderWidth
            
            shapeView.layer.addSublayer(starLayer)
            
        case .oval:
            shapeView.layer.cornerRadius = 20
            shapeView.layer.borderColor = borderColor
            shapeView.layer.borderWidth = borderWidth
            NSLayoutConstraint.activate([
                shapeView.widthAnchor.constraint(equalToConstant: 40),
                shapeView.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
        
        button.addTarget(self, action: #selector(shapeButtonTapped(_:)), for: .touchUpInside)
        
        switch shape {
        case .rectangle: button.tag = 0
        case .square: button.tag = 1
        case .circle: button.tag = 2
        case .triangle: button.tag = 3
        case .pentagon: button.tag = 4
        case .hexagon: button.tag = 5
        case .star: button.tag = 6
        case .oval: button.tag = 7
        }
    }

    
    @objc private func colorButtonTapped() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = selectedColor
        colorPicker.delegate = self
        
        if let rootVC = findViewController() {
            rootVC.present(colorPicker, animated: true, completion: nil)
        }
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            responder = nextResponder
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    @objc private func shapeButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0: updateSelectedShape(.rectangle)
        case 1: updateSelectedShape(.square)
        case 2: updateSelectedShape(.circle)
        case 3: updateSelectedShape(.triangle)
        case 4: updateSelectedShape(.pentagon)
        case 5: updateSelectedShape(.hexagon)
        case 6: updateSelectedShape(.star)
        case 7: updateSelectedShape(.oval)
        default: updateSelectedShape(.rectangle)
        }
    }
    
    private func updateSelectedShape(_ shape: DraggableShapeView.ShapeType) {
        rectangleButton.layer.borderWidth = 0
        squareButton.layer.borderWidth = 0
        circleButton.layer.borderWidth = 0
        triangleButton.layer.borderWidth = 0
        pentagonButton.layer.borderWidth = 0
        hexagonButton.layer.borderWidth = 0
        starButton.layer.borderWidth = 0
        ovalButton.layer.borderWidth = 0
        
        switch shape {
        case .rectangle:
            rectangleButton.layer.borderWidth = 3
            rectangleButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .square:
            squareButton.layer.borderWidth = 3
            squareButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .circle:
            circleButton.layer.borderWidth = 3
            circleButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .triangle:
            triangleButton.layer.borderWidth = 3
            triangleButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .pentagon:
            pentagonButton.layer.borderWidth = 3
            pentagonButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .hexagon:
            hexagonButton.layer.borderWidth = 3
            hexagonButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .star:
            starButton.layer.borderWidth = 3
            starButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .oval:
            ovalButton.layer.borderWidth = 3
            ovalButton.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        selectedShape = shape
    }
    
    private func updateShapeColors() {
        if let rectangleShapeView = rectangleButton.viewWithTag(100) {
            rectangleShapeView.backgroundColor = selectedColor
        }
        
        if let squareShapeView = squareButton.viewWithTag(100) {
            squareShapeView.backgroundColor = selectedColor
        }
        
        if let circleShapeView = circleButton.viewWithTag(100) {
            circleShapeView.backgroundColor = selectedColor
        }
        
        func updateLayerColor(in button: UIButton) {
            if let shapeView = button.viewWithTag(100) {
                if let shapeLayer = shapeView.layer.sublayers?.first as? CAShapeLayer {
                    shapeLayer.fillColor = selectedColor.cgColor
                }
            }
        }
        
        updateLayerColor(in: triangleButton)
        updateLayerColor(in: pentagonButton)
        updateLayerColor(in: hexagonButton)
        updateLayerColor(in: starButton)
        
        if let ovalShapeView = ovalButton.viewWithTag(100) {
            ovalShapeView.backgroundColor = selectedColor
        }
        
        colorButton.backgroundColor = .gray
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
    
    @objc private func doneTapped() {
        onAddShape?(selectedShape, selectedColor)
    }
}

extension ShapePickerView: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        updateShapeColors()
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        updateShapeColors()
    }
}

extension UIColor {
    func getBrightness() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ((red * 299) + (green * 587) + (blue * 114)) / 1000
    }
}
