import Cocoa

enum FilePickerResult {
    case success(url: URL)
    case cancelled
    case failed(reason: String)
}

extension NSOpenPanel {

    /// Shows a file picker and returns the result in a completion handler
    static func pickFile(extension_: String? = nil,
                         canChooseDirectories: Bool = false,
                         allowsMultipleSelection: Bool = false,
                         window: NSWindow,
                         title:String?,
                         completion: @escaping (FilePickerResult) -> Void) {
        
        let panel = NSOpenPanel()
        panel.title = title.map { $0 } ??  "Choose a file"
        panel.canChooseFiles = true
        panel.canChooseDirectories = canChooseDirectories
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.allowedFileTypes = extension_.map { [$0] } ?? []
        panel.showsHiddenFiles = false
        panel.canCreateDirectories = false
        
        panel.beginSheetModal(for: window) { response in
                 switch response {
                 case .OK:
                     if let url = panel.urls.first {
                         completion(.success(url: url))
                     } else {
                         completion(.failed(reason: "NSOpenPanel returned OK but no URL found"))
                     }
                 case .cancel:
                     completion(.cancelled)
                 default:
                     completion(.failed(reason: "Unknown NSOpenPanel response: \(String(describing: response))"))
                 }
             }
    }
}

/// Result type for save panel
enum SaveFileResult {
    case success
    case cancelled
    case failed(reason: String)
}

extension NSSavePanel {

    /// Shows a save dialog and moves the file at [filePath] to the selected location
    static func saveFile(filePath: String,
                         defaultFileName: String,
                         extension_: String,
                         window: NSWindow,
                         title:String?,
                         completion: @escaping (SaveFileResult) -> Void) {

        let panel = NSSavePanel()
        panel.title = title.map { $0 } ?? "Save File"
        panel.nameFieldStringValue = defaultFileName
        panel.allowedFileTypes = [extension_]
        panel.showsHiddenFiles = false
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.beginSheetModal(for: window) { response in
            switch response {
            case .OK:
                if let destinationURL = panel.url {
                    let sourceURL = URL(fileURLWithPath: filePath)
                    do {
                        // Move file (you can also use copy if you prefer)
                        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        completion(.success)
                    } catch {
                        completion(.failed(reason: "Failed to move file: \(error.localizedDescription)"))
                    }
                } else {
                    completion(.failed(reason: "NSSavePanel returned OK but no URL found"))
                }
            case .cancel:
                completion(.cancelled)
            default:
                completion(.failed(reason: "Unknown NSSavePanel response: \(response.rawValue)"))
            }
        }
    }
}
