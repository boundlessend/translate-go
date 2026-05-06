import AppKit

struct PasteboardSnapshot {
    let items: [PasteboardSnapshotItem]

    init(pasteboard: NSPasteboard) {
        let items = pasteboard.pasteboardItems ?? []
        self.items = items.map { item in
            let values: [NSPasteboard.PasteboardType: Data] = item.types.reduce(into: [:]) { result, type in
                guard let data = item.data(forType: type) else {
                    return
                }

                result[type] = data
            }

            return PasteboardSnapshotItem(values: values)
        }
    }

    func restore(to pasteboard: NSPasteboard) throws {
        pasteboard.clearContents()

        guard items.isEmpty == false else {
            return
        }

        let restoredItems = items.map { snapshotItem in
            let pasteboardItem = NSPasteboardItem()
            snapshotItem.values.forEach { type, data in
                pasteboardItem.setData(data, forType: type)
            }
            return pasteboardItem
        }

        guard pasteboard.writeObjects(restoredItems) else {
            throw AppError.pasteboardRestoreFailed
        }
    }
}

struct PasteboardSnapshotItem {
    let values: [NSPasteboard.PasteboardType: Data]
}
