# SaneSwift

Welcome travelers!

This package allows you to easily integrate SANE with the `net` backend into your own iOS app!

## History

After years working on [Backlit](https://apps.apple.com/fr/app/backlit/id1203029238?), I have extracted all the code related to SANE builds and Swift wrapper to its own repository.

> [!NOTE]
> Commits before May 2024 are from the [Backlit repository](https://github.com/dvkch/Backlit), hence the sometimes misleading commit messages.

## Example

```swift
import SaneSwift

func listDevices() {
    SaneSetLogLevel(0)
    SaneLogger.externalLoggingMethod = { level, message in
        guard level >= .error else { return }
        print(message)
    }

    Sane.shared.configuration.hosts = [.init(hostname: "192.168.13.12", displayName: "My Server")]

    Sane.shared.updateDevices { result in
        switch result {
        case .success(let devices):
            print("Found devices:", devices)
            if let device = devices.first {
                self.openDevice(device)
            }
        case .failure(let error):
            print("Encountered error:", error)
        }
    }
}
    
func openDevice(_ device: Device) {
    print("Opening device:", device.name)
    Sane.shared.openDevice(device) { result in
        switch result {
        case .success(let devices):
            print("Opened")
            self.scan(using: device)
        case .failure(let error):
            print("Encountered error:", error)
        }    }
}

func scan(using device: Device) {
    print("Starting scan using", device.name)
    Sane.shared.scan(device: device) { status in
        guard let status else { return }
        switch status.progress {
        case .warmingUp:
            print("Warming up")
        case .scanning(let progress, let finishedDocs, let incompletePreview, let parameters):
            print("Progress: \(Int(progress * 100))% of current doc, finished \(finishedDocs) docs, parameters: \(parameters)")
        case .cancelling:
            print("Cancelling")
        }
    } completion: { result in
        switch result {
        case .success(let scannedDocuments):
            print("Finished scanning \(scannedDocuments.count) documents")
        case .failure(let error):
            print("Encountered error:", error)
        }
    }
}
```

```
Found devices: [Device: net:192.168.13.12:genesys:libusb:001:002, flatbed scanner, Canon, LiDE 220, 0 options, Device: net:192.168.13.12:test:0, virtual device, Noname, frontend-tester, 0 options]
Opening device: net:192.168.13.12:genesys:libusb:001:002
Opened
Starting scan using net:192.168.13.12:genesys:libusb:001:002
Warming up
Progress: 2% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
Progress: 6% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
Progress: 16% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
Progress: 30% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
...
Progress: 99% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
Progress: 100% of current doc, finished 0 docs, parameters: ScanParameters: 636x878x8, format: GRAY, isLast: true, bytesPerLine: 636
Finished scanning 1 documents
```

## Useful links

The following links have helped me a great deal in the making of this app, if you're building a desktop lib for iOS you may find them useful to!

##### CrossCompiling Sane

- <https://github.com/tpoechtrager/cctools-port/issues/6>
- <https://github.com/obfuscator-llvm/obfuscator/issues/13>
- <https://help.ubuntu.com/community/CompileSaneFromSource>
- <http://stackoverflow.com/questions/26812060/cross-compile-libgcrypt-static-lib-for-use-on-ios>
- <https://ghc.haskell.org/trac/ghc/wiki/Building/CrossCompiling/iOS>

##### Sane API doc

- <http://www.sane-project.org/html/doc012.html>

##### Other Sane projects

- <https://github.com/chrspeich/SaneNetScanner>
- <https://hackaday.io/project/172440-simple-saned-front-end-for-osx>

