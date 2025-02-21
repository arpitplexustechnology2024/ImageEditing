//
//  ViewController.swift
//  ImageEditing
//
//  Created by Arpit iOS Dev. on 21/02/25.
//

import UIKit
import AVFoundation
import Photos
import Mantis
import PencilKit

// MARK: - Filter Collection View Cell
class FilterCollectionViewCell: UICollectionViewCell {
    static let identifier = "FilterCollectionViewCell"
    
    let filterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    let filterNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.font = .systemFont(ofSize: 12)
        label.layer.cornerRadius = 10
        label.textColor = .white
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = isSelected ? 2 : 0
            self.layer.borderColor = isSelected ? UIColor.white.cgColor : nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.contentView.layer.cornerRadius = 10
        self.layer.cornerRadius = 10
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(filterImageView)
        contentView.addSubview(filterNameLabel)
        
        filterImageView.translatesAutoresizingMaskIntoConstraints = false
        filterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            filterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            filterNameLabel.heightAnchor.constraint(equalToConstant: 20),
            filterNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - Main View Controller
class ImageEditingVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var addImageButton: UIBarButtonItem!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    private var image: UIImage?
    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker?
    private var drawingStack: [PKDrawing] = []
    private var redoStack: [PKDrawing] = []
    private var isDrawingMode = false
    
    var originalImage: UIImage?
    private var selectedFilterIndex: Int = 0
    private var doneButton: UIBarButtonItem!
    private var isFilterViewVisible = false
    
    private let filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 70)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let filters = ["Original", "Vivid", "Dramatic", "Mono", "Nashville", "Toaster", "1977", "Noir", "Comic", "Crystallize", "Bloom", "Pixellate", "Blur", "Sepia", "Fade", "Sharpen", "HDR", "Vignette", "Tonal", "Dot Matrix", "Edge Work", "X-Ray", "Posterize"]
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        imageview.isUserInteractionEnabled = true
        setupUI()
        setupFilterCollectionView()
        setupDoneButton()
        updateButtonStates()
        setupDrawingCanvas()
    }
    
    private func setupDrawingCanvas() {
        canvasView = PKCanvasView(frame: .zero)
        canvasView.isHidden = true
        canvasView.backgroundColor = .clear
        canvasView.delegate = self
        imageview.addSubview(canvasView)
        
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        }
    }
    
    private func setupUI() {
        cropButton.layer.cornerRadius = 10
        filterButton.layer.cornerRadius = 10
        brushButton.layer.cornerRadius = 10
        saveButton.layer.cornerRadius = 10
        
        cropButton.isEnabled = false
        filterButton.isEnabled = false
        brushButton.isEnabled = false
        saveButton.isEnabled = false
        
        cropButton.alpha = 0.5
        filterButton.alpha = 0.5
        brushButton.alpha = 0.5
        saveButton.alpha = 0.5
    }
    
    private func setupDoneButton() {
        doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.rightBarButtonItem = nil
    }
    
    private func updateCanvasFrame() {
        guard let image = imageview.image else { return }
        
        let imageAspect = image.size.width / image.size.height
        let viewAspect = imageview.bounds.width / imageview.bounds.height
        
        var drawingFrame = CGRect.zero
        
        if imageAspect > viewAspect {
            let height = imageview.bounds.width / imageAspect
            drawingFrame.size.width = imageview.bounds.width
            drawingFrame.size.height = height
            drawingFrame.origin.y = (imageview.bounds.height - height) / 2
        } else {
            let width = imageview.bounds.height * imageAspect
            drawingFrame.size.height = imageview.bounds.height
            drawingFrame.size.width = width
            drawingFrame.origin.x = (imageview.bounds.width - width) / 2
        }
        
        canvasView.frame = drawingFrame
    }
    
    
    @IBAction func brushButtonTapped(_ sender: UIButton) {
        isDrawingMode.toggle()
        
        if isDrawingMode {
            enableDrawing()
        } else {
            disableDrawing()
        }
    }
    
    private func enableDrawing() {
        updateCanvasFrame()
        canvasView.isHidden = false
        navigationItem.rightBarButtonItem = doneButton
        
        if canvasView.drawing.bounds.isEmpty {
            canvasView.drawing = PKDrawing()
        }
        
        if let toolPicker = toolPicker {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        if !drawingStack.contains(canvasView.drawing) {
            drawingStack.append(canvasView.drawing)
        }
    }
    
    private func disableDrawing() {
        canvasView.isHidden = true
        navigationItem.rightBarButtonItem = nil
        
        if let toolPicker = toolPicker {
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            toolPicker.removeObserver(canvasView)
        }
        
        mergeDrawingWithImage()
    }
    
    private func mergeDrawingWithImage() {
        guard let image = imageview.image else { return }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let scale = image.size.width / canvasView.bounds.width
        let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: scale)
        drawingImage.draw(in: CGRect(origin: .zero, size: image.size))
        
        if let mergedImage = UIGraphicsGetImageFromCurrentImageContext() {
            imageview.image = mergedImage
            self.originalImage = mergedImage
        }
        
        UIGraphicsEndImageContext()
        canvasView.drawing = PKDrawing()
        drawingStack.removeAll()
        redoStack.removeAll()
    }
    
    
    @objc private func drawingDoneButtonTapped() {
        disableDrawing()
    }
    
    @objc private func doneButtonTapped() {
        isDrawingMode = false
        disableDrawing()
        
        if isFilterViewVisible {
            hideFilterView()
        }
    }
    
    private func hideFilterView() {
        isFilterViewVisible = false
        navigationItem.rightBarButtonItem = nil
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseIn) {
            self.filterCollectionView.transform = CGAffineTransform(translationX: 0, y: 200)
            self.filterCollectionView.alpha = 0
        }
    }
    
    private func setupFilterCollectionView() {
        view.addSubview(filterCollectionView)
        filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filterCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterCollectionView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -20),
            filterCollectionView.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
        filterCollectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
        
        filterCollectionView.transform = CGAffineTransform(translationX: 0, y: 200)
        filterCollectionView.alpha = 0
    }
    
    private func updateButtonStates() {
        let hasImage = imageview.image != nil
        cropButton.isEnabled = hasImage
        filterButton.isEnabled = hasImage
        brushButton.isEnabled = hasImage
        saveButton.isEnabled = hasImage
        
        cropButton.alpha = hasImage ? 1.0 : 0.5
        filterButton.alpha = hasImage ? 1.0 : 0.5
        brushButton.alpha = hasImage ? 1.0 : 0.5
        saveButton.alpha = hasImage ? 1.0 : 0.5
    }
    
    @IBAction func cropButtonTapped(_ sender: UIButton) {
        guard let imageToCrop = imageview.image else { return }
        hideFilterView()
        presentCropViewController(image: imageToCrop)
    }
    
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        guard imageview.image != nil else { return }
        
        isFilterViewVisible.toggle()
        
        if isFilterViewVisible {
            filterCollectionView.isHidden = false
            navigationItem.rightBarButtonItem = doneButton
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.filterCollectionView.transform = .identity
                self.filterCollectionView.alpha = 1
            }
            
            let indexPath = IndexPath(item: selectedFilterIndex, section: 0)
            filterCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            filterCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            hideFilterView()
        }
    }
    
    @IBAction func addImageButtonTapped(_ sender: UIBarButtonItem) {
        showImageSourceOptions()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let imageToSave = imageview.image else {
            let alert = UIAlertController(title: "Error", message: "No image to save", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    let alert = UIAlertController(title: "Success", message: "Image saved successfully", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                } else {
                    let alert = UIAlertController(title: "Error", message: "Failed to save image: \(error?.localizedDescription ?? "Unknown error")", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Image Picker Methods
    func showImageSourceOptions() {
        let alert = UIAlertController(title: "Select Image", message: "Choose an option", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.requestCameraAccess()
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { _ in
            self.requestGalleryAccess()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func requestCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            openImagePicker(sourceType: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.openImagePicker(sourceType: .camera)
                    }
                }
            }
        case .denied, .restricted:
            showSettingsAlert(title: "Camera Access Denied", message: "Enable camera access in Settings.")
        @unknown default:
            break
        }
    }
    
    func requestGalleryAccess() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            openImagePicker(sourceType: .photoLibrary)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.openImagePicker(sourceType: .photoLibrary)
                    }
                }
            }
        case .denied, .restricted:
            showSettingsAlert(title: "Gallery Access Denied", message: "Enable photo library access in Settings.")
        @unknown default:
            break
        }
    }
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            self.originalImage = selectedImage
            self.imageview.image = selectedImage
            self.selectedFilterIndex = 0
            self.filterCollectionView.reloadData()
            
            if isFilterViewVisible {
                hideFilterView()
            }
            
            updateButtonStates()
            picker.dismiss(animated: true, completion: nil)
        } else {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Filter Methods
    private func applyFilter(filterName: String) {
        guard let original = originalImage else { return }
        
        if filterName == "Original" {
            imageview.image = original
            return
        }
        
        guard let ciImage = CIImage(image: original) else { return }
        let context = CIContext(options: nil)
        
        if let filter = createFilter(name: filterName) {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            if let outputImage = filter.outputImage,
               let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                imageview.image = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func createFilter(name: String) -> CIFilter? {
        switch name {
        case "Vivid":
            return CIFilter(name: "CIPhotoEffectChrome")
        case "Dramatic":
            return CIFilter(name: "CIPhotoEffectTransfer")
        case "Mono":
            return CIFilter(name: "CIPhotoEffectMono")
        case "Nashville":
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(0.8, forKey: kCIInputIntensityKey)
            return filter
        case "Toaster":
            return CIFilter(name: "CIPhotoEffectInstant")
        case "1977":
            return CIFilter(name: "CIPhotoEffectProcess")
        case "Noir":
            return CIFilter(name: "CIPhotoEffectNoir")
        case "Comic":
            return CIFilter(name: "CIComicEffect")
        case "Crystallize":
            let filter = CIFilter(name: "CICrystallize")
            filter?.setValue(25.0, forKey: kCIInputRadiusKey)
            return filter
        case "Bloom":
            let filter = CIFilter(name: "CIBloom")
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            return filter
        case "Pixellate":
            let filter = CIFilter(name: "CIPixellate")
            filter?.setValue(8.0, forKey: kCIInputScaleKey)
            return filter
        case "Blur":
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(25.0, forKey: kCIInputRadiusKey)
            return filter
        case "Sepia":
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(0.7, forKey: kCIInputIntensityKey)
            return filter
        case "Fade":
            return CIFilter(name: "CIPhotoEffectFade")
        case "Sharpen":
            let filter = CIFilter(name: "CISharpenLuminance")
            filter?.setValue(1.0, forKey: kCIInputSharpnessKey)
            return filter
        case "HDR":
            let filter = CIFilter(name: "CIHighlightShadowAdjust")
            filter?.setValue(1.0, forKey: "inputHighlightAmount")
            filter?.setValue(4.0, forKey: "inputShadowAmount")
            return filter
        case "Vignette":
            let filter = CIFilter(name: "CIVignette")
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            filter?.setValue(2.0, forKey: kCIInputRadiusKey)
            return filter
        case "Tonal":
            return CIFilter(name: "CIPhotoEffectTonal")
        case "Dot Matrix":
            let filter = CIFilter(name: "CIDotScreen")
            filter?.setValue(2.0, forKey: kCIInputSharpnessKey)
            return filter
        case "Edge Work":
            let filter = CIFilter(name: "CIEdges")
            filter?.setValue(5.0, forKey: kCIInputIntensityKey)
            return filter
        case "X-Ray":
            return CIFilter(name: "CIColorInvert")
        case "Posterize":
            let filter = CIFilter(name: "CIColorPosterize")
            filter?.setValue(8.0, forKey: "inputLevels")
            return filter
        default:
            return nil
        }
    }
    
    private func applyFilterToImage(_ image: UIImage, filterName: String) -> UIImage {
        if filterName == "Original" {
            return image
        }
        
        guard let ciImage = CIImage(image: image),
              let filter = createFilter(name: filterName) else { return image }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        let context = CIContext(options: nil)
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
    
    func showSettingsAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Collection View Delegate & DataSource
extension ImageEditingVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier, for: indexPath) as? FilterCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let filterName = filters[indexPath.item]
        cell.filterNameLabel.text = filterName
        
        if let originalImage = originalImage {
            let filteredImage = applyFilterToImage(originalImage, filterName: filterName)
            cell.filterImageView.image = filteredImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        let filterName = filters[indexPath.item]
        applyFilter(filterName: filterName)
    }
}

// MARK: - Mantis CropViewController Delegate
extension ImageEditingVC: CropViewControllerDelegate {
    func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        originalImage = cropped
        imageview.image = cropped
        selectedFilterIndex = 0
        filterCollectionView.reloadData()
        updateButtonStates()
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage) {
        originalImage = cropped
        imageview.image = cropped
        filterCollectionView.reloadData()
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func presentCropViewController(image: UIImage) {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = self
        present(cropViewController, animated: true, completion: nil)
    }
}


// MARK: - PKCanvasViewDelegate
extension ImageEditingVC: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        drawingStack.append(canvasView.drawing)
        redoStack.removeAll()
    }
}
