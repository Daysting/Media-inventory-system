import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Embed cover bytes in the inventory so an iCloud snapshot is self-contained.
/// Existing local/remote URLs are converted when accessible; failed migrations
/// retain the original value so users can select the image again.
enum InventoryImage {
    static let prefix = "data:application/octet-stream;base64,"

    static func data(from value: String) -> Data? {
        guard value.hasPrefix(prefix) else { return nil }
        return Data(base64Encoded: String(value.dropFirst(prefix.count)))
    }

    static func storageValue(_ raw: String) throws -> String {
        if data(from: raw) != nil { return raw }
        let url: URL
        if let parsed = URL(string: raw), let scheme = parsed.scheme?.lowercased(), ["https", "http", "file"].contains(scheme) {
            url = parsed
        } else {
            url = URL(fileURLWithPath: (raw as NSString).expandingTildeInPath)
        }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let bytes = try Data(contentsOf: url)
        guard bytes.count <= 8 * 1024 * 1024, NSBitmapImageRep(data: bytes) != nil else {
            throw NSError(domain: "MediaInventory.Image", code: 1, userInfo: [NSLocalizedDescriptionKey: "Choose an image smaller than 8 MB."])
        }
        return prefix + bytes.base64EncodedString()
    }
}

struct InventoryImageField: View {
    @Binding var value: String
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if InventoryImage.data(from: value) != nil {
                    Label("Cover saved with inventory", systemImage: "photo")
                } else {
                    TextField("Image URL", text: $value)
                }
                Button("Choose Image…", action: chooseImage)
                if !value.isEmpty { Button("Remove") { value = "" } }
            }
            if let error { Text(error).foregroundColor(.red).font(.caption) }
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            value = try InventoryImage.storageValue(url.absoluteString)
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

struct InventoryCover: View {
    let value: String?
    var body: some View {
        if let value, let bytes = InventoryImage.data(from: value), let image = NSImage(data: bytes) {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
        } else if let value, let url = URL(string: value), url.isFileURL, let image = NSImage(contentsOf: url) {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
        } else {
            AsyncImage(url: value.flatMap(URL.init(string:))) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.12)
                    Image(systemName: "photo").font(.system(size: 32)).foregroundColor(.secondary)
                }
            }
        }
    }
}
