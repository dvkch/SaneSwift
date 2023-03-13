//
//  UIImage+SaneSwift.swift
//  SaneScanner
//
//  Created by Stanislas Chevallier on 30/01/19.
//  Copyright (c) 2019 Syan. All rights reserved.
//

import UIKit
import ImageIO
import CommonCrypto

@propertyWrapper
internal struct SaneLocked<Value> {
    private var lock = NSLock()
    private var _stored: Value

    public init(wrappedValue initialValue: Value) {
      _stored = initialValue
    }

    public var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }

            return _stored
        }
        set(newValue) {
            lock.lock()
            defer { lock.unlock() }

            _stored = newValue
        }
    }
}

internal extension String {
    func md5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = data(using: .utf8) {
            _ = d.withUnsafeBytes {
                CC_MD5($0.baseAddress, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
}

internal extension Numeric where Self: Comparable {
    func clamped(min: Self, max: Self) -> Self {
        return Swift.max(min, Swift.min(max, self))
    }
}

internal extension Collection {
    func subarray(maxCount: Int) -> Self.SubSequence {
        let max = Swift.min(maxCount, count)
        let maxIndex = index(startIndex, offsetBy: max)
        return self[startIndex..<maxIndex]
    }
}

internal extension Collection where Element: Comparable {
    func closest(to value: Element) -> Element? {
        let sorted = self.sorted()
        return sorted.first(where: { $0 >= value }) ?? sorted.last(where: { $0 <= value })
    }
}

internal extension Result {
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

internal extension UIImage {
    // Nota: if the source image is 1 bit Grayscale (monochrome), the method `pngData()` on the output UIImage will
    // produce an invalid file (at least on macOS 13.2.1), but using CGImageDestinationCreateWithData with kUTTypePNG
    // will produce a valid PNG file.
    static func sy_imageFromSane(data: Data, parameters: ScanParameters, previousFrames: [ScanImage]) throws -> UIImage {
        // TODO: release pool necessary ?
        return try autoreleasepool {
            guard let provider = CGDataProvider(data: data as CFData) else {
                throw SaneError.noImageData
            }

            let colorSpace: CGColorSpace

            switch parameters.currentlyAcquiredFrame {
            case SANE_FRAME_RGB:
                colorSpace = CGColorSpaceCreateDeviceRGB()
            case SANE_FRAME_GRAY:
                colorSpace = CGColorSpaceCreateDeviceGray()
            case SANE_FRAME_RED, SANE_FRAME_GREEN, SANE_FRAME_BLUE:
                colorSpace = CGColorSpaceCreateDeviceRGB()
            default:
                throw SaneError.unsupportedChannels
            }
            
            var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            if parameters.depth >= 16 {
                bitmapInfo.insert(CGBitmapInfo(rawValue: CGImageByteOrderInfo.order16Little.rawValue))
            }
            
            guard let cgImage = CGImage(
                width: parameters.width,
                height: parameters.height,
                bitsPerComponent: parameters.depth,
                bitsPerPixel: parameters.depth * parameters.numberOfChannels * parameters.expectedFramesCount,
                bytesPerRow: parameters.bytesPerLine * parameters.expectedFramesCount,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            ) else {
                throw SaneError.cannotGenerateImage
            }

            return UIImage(cgImage: cgImage)
        }
    }

    static func sy_imageFromIncompleteSane(data: Data, parameters: ScanParameters, previousFrames: [ScanImage]) throws -> UIImage {
        let size = (parameters.fileSize * parameters.expectedFramesCount) - data.count
        let completedData = data + Data(repeating: UInt8.max, count: size)
        return try self.sy_imageFromSane(data: completedData, parameters: parameters, previousFrames: previousFrames)
    }
}

/*
// LATER: work on big images
// to stream lower resolutions :
// - https://twitter.com/PDucks32/status/1417553099825238028
// - https://developer.apple.com/documentation/uikit/uiimage/building_high-performance_lists_and_collection_views
+ (void)sy_convertTempImage
{
    SYSaneScanParameters *params = [[SYSaneScanParameters alloc] init];
    params.acquiringLastChannel = YES;
    params.currentlyAcquiredChannel = SANE_FRAME_RGB;
    params.width = 10208;
    params.height = 14032;
    params.bytesPerLine = params.width * 3;
    params.depth = 8;
    
    
    NSString *sourceFileName = [[SYTools documentsPath] stringByAppendingPathComponent:$$("scan.tmp")];
    NSString *destinationFileName = [[SYTools documentsPath] stringByAppendingPathComponent:$$("scan.jpg")];
    
    NSDate *date = [NSDate date];
    
    UIImage *img = [self sy_imageFromRGBData:nil orFileURL:[NSURL fileURLWithPath:sourceFileName] saneParameters:params error:NULL];
    NSData *data = UIImageJPEGRepresentation(img, JPEG_COMP);
    [data writeToFile:destinationFileName atomically:YES];
    
    NSLog($$("-> %@ in %.03lfs"), img, [[NSDate date] timeIntervalSinceDate:date]);
}
*/

