//
//  TextEditorView.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 25/02/25.
//

import UIKit
import AVFoundation

class TextEditorView: UIView, UITextFieldDelegate {
    
    // MARK: - Properties
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .red
        return button
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter the text"
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Color Select:-"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let colorPickerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let fontLabel: UILabel = {
        let label = UILabel()
        label.text = "Font Select:-"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let fontPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    
    private let fontStyleLabel: UILabel = {
        let label = UILabel()
        label.text = "Font Style Select:-"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let fontStyleSegment: UISegmentedControl = {
        let items = ["regular", "Bold", "Italic", "Semi-Bold"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let colors: [(String, UIColor)] = [
        ("Black", .black),
        ("White", .white),
        ("Red", .red),
        ("Blue", .blue),
        ("Green", .green),
        ("Yellow", .yellow)
    ]
    
    private var fonts: [String] = []
    
    private var selectedColor: UIColor = .black
    private var selectedFont: String = "Helvetica"
    private var selectedFontStyle: UIFont.Weight = .regular
    
    var onAddText: ((String, UIColor, UIFont) -> Void)?
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupFontData()
        setupColorButtons()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        endEditing(true)
    }
    
    // MARK: - Setup methods
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 5)
        
        textField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        addGestureRecognizer(tapGesture)
        
        addSubview(closeButton)
        addSubview(textField)
        addSubview(colorLabel)
        addSubview(colorPickerView)
        addSubview(fontLabel)
        addSubview(fontPickerView)
        
        addSubview(fontStyleLabel)
        addSubview(fontStyleSegment)
        addSubview(addButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorPickerView.translatesAutoresizingMaskIntoConstraints = false
        fontLabel.translatesAutoresizingMaskIntoConstraints = false
        fontPickerView.translatesAutoresizingMaskIntoConstraints = false
        
        fontStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        fontStyleSegment.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            textField.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            colorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            colorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            colorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            colorPickerView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8),
            colorPickerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            colorPickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            colorPickerView.heightAnchor.constraint(equalToConstant: 50),
            
            fontLabel.topAnchor.constraint(equalTo: colorPickerView.bottomAnchor, constant: 20),
            fontLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fontLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            fontPickerView.topAnchor.constraint(equalTo: fontLabel.bottomAnchor, constant: 8),
            fontPickerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fontPickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            fontPickerView.heightAnchor.constraint(equalToConstant: 150),
            
            fontStyleLabel.topAnchor.constraint(equalTo: fontPickerView.bottomAnchor, constant: 20),
            fontStyleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fontStyleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            fontStyleSegment.topAnchor.constraint(equalTo: fontStyleLabel.bottomAnchor, constant: 8),
            fontStyleSegment.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            fontStyleSegment.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            fontStyleSegment.heightAnchor.constraint(equalToConstant: 44),
            
            addButton.topAnchor.constraint(equalTo: fontStyleSegment.bottomAnchor, constant: 24),
            addButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 120),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
        
        fontPickerView.delegate = self
        fontPickerView.dataSource = self
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    private func setupFontData() {
        fonts = UIFont.familyNames.sorted()
        fontPickerView.reloadAllComponents()
    }
    
    private func setupColorButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        colorPickerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: colorPickerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: colorPickerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: colorPickerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: colorPickerView.trailingAnchor)
        ])
        
        for (index, colorOption) in colors.enumerated() {
            let colorButton = UIButton()
            colorButton.backgroundColor = colorOption.1
            colorButton.layer.cornerRadius = 15
            colorButton.layer.borderWidth = 2
            colorButton.layer.borderColor = UIColor.lightGray.cgColor
            colorButton.tag = index
            
            if index == 0 {
                colorButton.layer.borderColor = UIColor.systemBlue.cgColor
                colorButton.layer.borderWidth = 3
            }
            
            colorButton.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(colorButton)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        onDismiss?()
    }
    
    @objc private func addButtonTapped() {
        guard let text = textField.text, !text.isEmpty else {
            shake()
            return
        }
        
        var fontWeight: UIFont.Weight = .regular
        
        switch fontStyleSegment.selectedSegmentIndex {
        case 0:
            fontWeight = .regular
        case 1:
            fontWeight = .bold
        case 2:
            fontWeight = .regular
        case 3:
            fontWeight = .semibold
        default:
            fontWeight = .regular
        }
        
        var font: UIFont
        
        if fontStyleSegment.selectedSegmentIndex == 2 {
            
            if let descriptor = UIFont(name: selectedFont, size: 17)?.fontDescriptor.withSymbolicTraits(.traitItalic) {
                font = UIFont(descriptor: descriptor, size: 17)
            } else {
                font = UIFont.italicSystemFont(ofSize: 17)
            }
        } else {
            
            if let customFont = UIFont(name: selectedFont, size: 17) {
                if let descriptor = customFont.fontDescriptor.withSymbolicTraits(.traitBold) {
                    font = UIFont(descriptor: descriptor, size: 17)
                } else {
                    font = UIFont.systemFont(ofSize: 17, weight: fontWeight)
                }
            } else {
                font = UIFont.systemFont(ofSize: 17, weight: fontWeight)
            }
        }
        
        onAddText?(text, selectedColor, font)
        onDismiss?()
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        
        for subview in colorPickerView.subviews.first?.subviews ?? [] {
            if let button = subview as? UIButton {
                button.layer.borderColor = UIColor.lightGray.cgColor
                button.layer.borderWidth = 2
            }
        }
        
        selectedColor = colors[sender.tag].1
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        sender.layer.borderWidth = 3
    }
    
    private func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        textField.layer.add(animation, forKey: "shake")
    }
}


// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension TextEditorView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fonts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return fonts[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFont = fonts[row]
    }
}

