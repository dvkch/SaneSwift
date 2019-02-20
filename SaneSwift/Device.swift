//
//  Device.swift
//  SaneScanner
//
//  Created by Stanislas Chevallier on 30/01/19.
//  Copyright (c) 2019 Syan. All rights reserved.
//

// TODO: Move
public enum SaneStandardOption: CaseIterable {
    case preview, resolution, resolutionX, resolutionY, colorMode, areaTopLeftX, areaTopLeftY, areaBottomRightX, areaBottomRightY
    
    var saneIdentifier: String {
        switch self {
        case .preview:          return SANE_NAME_PREVIEW
        case .resolution:       return SANE_NAME_SCAN_RESOLUTION
        case .resolutionX:      return SANE_NAME_SCAN_X_RESOLUTION
        case .resolutionY:      return SANE_NAME_SCAN_Y_RESOLUTION
        case .colorMode:        return SANE_NAME_SCAN_MODE
        case .areaTopLeftX:     return SANE_NAME_SCAN_TL_X
        case .areaTopLeftY:     return SANE_NAME_SCAN_TL_Y
        case .areaBottomRightX: return SANE_NAME_SCAN_BR_X
        case .areaBottomRightY: return SANE_NAME_SCAN_BR_Y
        }
    }

    init?(saneIdentifier: String?) {
        guard let option = SaneStandardOption.allCases.first(where: { $0.saneIdentifier == saneIdentifier }) else { return nil }
        self = option
    }
    
    static var cropOptions: [SaneStandardOption] {
        return [.areaTopLeftX, .areaTopLeftY, .areaBottomRightX, .areaBottomRightY]
    }

    public enum PreviewValue {
        case auto, min, max
    }

    var bestPreviewValue: PreviewValue {
        switch self {
        case .preview, .colorMode:                      return .auto
        case .resolution, .resolutionX, .resolutionY:   return .min
        case .areaTopLeftX, .areaTopLeftY:              return .min
        case .areaBottomRightX, .areaBottomRightY:      return .max
        }
    }
}

public class Device {
    // MARK: Initializers
    init(name: String, type: String, vendor: String, model: String) {
        self.name = name
        self.type = type
        self.vendor = vendor
        self.model = model
    }
    
    init(cDevice: SANE_Device) {
        self.name   = cDevice.name.asString()   ?? ""
        self.model  = cDevice.model.asString()  ?? ""
        self.vendor = cDevice.vendor.asString() ?? ""
        self.type   = Sane.shared.translation(for: cDevice.type.asString() ?? "")
    }
    
    // MARK: Device properties
    public let name: String
    public let type: String
    public let vendor: String
    public let model: String
    
    // MARK: Options
    public internal(set) var options = [DeviceOption]() {
        didSet {
            updateCropArea()
        }
    }
    
    // MARK: Cache properties
    public var lastPreviewImage: UIImage?
    public var cropArea: CGRect = .zero
}

// MARK: Options
extension Device {
    public func groupedOptions(includeAdvanced: Bool) -> [DeviceOptionGroup] {
        var filteredOptions = options
            .filter { $0.identifier != SaneStandardOption.preview.saneIdentifier }
        
        if canCrop {
            let cropOptionsIDs = SaneStandardOption.cropOptions.map { $0.saneIdentifier }
            filteredOptions.removeAll(where: { $0.identifier != nil && cropOptionsIDs.contains($0.identifier!) })
        }
        
        if !includeAdvanced {
            filteredOptions.removeAll(where: { $0.capabilities.contains(.advanced) })
        }
        
        return DeviceOption.groupedOptions(filteredOptions, removeEmpty: true)
    }
    
    public func standardOption(for stdOption: SaneStandardOption) -> DeviceOption? {
        return option(with: stdOption.saneIdentifier)
    }
    
    public func option(with identifier: String) -> DeviceOption? {
        return options.first(where: { $0.identifier == identifier })
    }
}

// MARK: Derived capacities
extension Device {
    public var canCrop: Bool {
        let existingSettableOptions = SaneStandardOption.cropOptions
            .compactMap { standardOption(for: $0) }
            .filter { $0.capabilities.isSettable && $0.capabilities.isActive }
        return existingSettableOptions.count == 4
    }
    
    public var maxCropArea: CGRect {
        // TODO: clean up
        let options = SaneStandardOption.cropOptions
            .compactMap { standardOption(for: $0) as? DeviceOptionNumber }
            .filter { $0.capabilities.isSettable && $0.capabilities.isActive }

        guard options.count == 4 else { return .zero }
        
        var tlX = Double(0), tlY = Double(0), brX = Double(0), brY = Double(0)
        
        options.forEach { (option) in
            if option.identifier == SaneStandardOption.areaTopLeftX.saneIdentifier {
                tlX = option.bestValueForPreview?.doubleValue ?? 0
            }
            if option.identifier == SaneStandardOption.areaTopLeftY.saneIdentifier {
                tlY = option.bestValueForPreview?.doubleValue ?? 0
            }
            if option.identifier == SaneStandardOption.areaBottomRightX.saneIdentifier {
                brX = option.bestValueForPreview?.doubleValue ?? 0
            }
            if option.identifier == SaneStandardOption.areaBottomRightY.saneIdentifier {
                brY = option.bestValueForPreview?.doubleValue ?? 0
            }
        }
        
        return CGRect(x: tlX, y: tlY, width: brX - tlX, height: brY - tlY)
    }
    
    public var previewImageRatio: CGFloat? {
        // TODO: was cached, still needed?
        guard !options.isEmpty else { return nil }
        if maxCropArea != .zero {
            return maxCropArea.width / maxCropArea.height
        }
        if let image = lastPreviewImage {
            return image.size.width / image.size.height
        }
        return nil
    }
    
    private func updateCropArea() {
        let maxCropArea = self.maxCropArea
        guard maxCropArea != .zero else {
            cropArea = .zero
            return
        }
        
        // keep old crop values if possible in case all options are refreshed
        cropArea = maxCropArea.intersection(cropArea)
        
        // define default value if current crop area is not defined
        if cropArea == .zero {
            cropArea = maxCropArea
        }
    }
}

// MARK: Helpers
extension Device {
    public var host: String {
        // TODO: ugly, hacky, definitely wrong. fix when we get the chance, remove if unused
        return name.components(separatedBy: ":").first ?? ""
    }
}

// MARK: CustomStringConvertible
extension Device : CustomStringConvertible {
    public var description: String {
        return "Device: \(name), \(type), \(vendor), \(model), \(options.count) options"
    }
}



