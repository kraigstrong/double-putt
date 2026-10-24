import MachO
import UIKit

/// Menu artwork: every hole's card and the title's backdrop. They take seconds to draw, so the loading screen draws
/// them once per build, saves them to Caches, and loads them from there on later launches. The menus only ever show
/// art that's ready, so they never draw while you scroll.
@MainActor
final class MenuArt {
    static let shared = MenuArt()
    private var cards: [String: UIImage] = [:]
    private var titleArt: (size: CGSize, image: UIImage)?

    /// A hole's card, once `prepare` has run.
    func card(_ level: Level) -> UIImage? { cards[level.name] }

    /// The title's backdrop for a screen of `size`: the one `prepare` loaded, or drawn now if the size has changed.
    func title(size: CGSize) -> UIImage {
        if let titleArt, titleArt.size == size { return titleArt.image }
        let image = Self.drawTitle(size: size)
        titleArt = (size, image)
        return image
    }

    /// Load the title and every hole's card from the cache, drawing (and saving) any that aren't there yet, several
    /// at once. `progress` hears the share done after each one.
    func prepare(_ levels: [Level], screen: CGSize, scale: CGFloat, progress: @escaping (Double) -> Void) async {
        let folder = Self.folder()
        // Two of the five columns across Free Play: a touch wider than a card (see CourseRow), so it stays crisp.
        let cardWidth = (screen.width * 0.4 * scale).rounded(.up)
        // The title first: it takes the longest. Its name is nil.
        let jobs: [(name: String?, file: URL, draw: () -> UIImage)] =
            [(nil, folder.appendingPathComponent("title-\(Int(screen.width))x\(Int(screen.height)).jpg"), { Self.drawTitle(size: screen) })]
            + levels.map { level in
                (level.name, folder.appendingPathComponent("card-\(Self.fileName(level.name))-\(Int(cardWidth)).jpg"),
                 { CourseArt.card(level, pixelWidth: cardWidth) })
            }
        await withTaskGroup(of: (String?, UIImage).self) { group in
            // One short of a job per core: with every thread drawing, the progress updates (and the rest of the app's
            // async work) would wait for the drawing to finish.
            var queue = jobs.makeIterator()
            func start() {
                guard let job = queue.next() else { return }
                group.addTask { (job.name, Self.cached(job.file, job.draw)) }
            }
            for _ in 0..<max(1, ProcessInfo.processInfo.activeProcessorCount - 1) { start() }
            var done = 0
            for await (name, image) in group {
                if let name { cards[name] = image } else { titleArt = (screen, image) }
                done += 1
                progress(Double(done) / Double(jobs.count))
                start()
            }
        }
    }

    nonisolated private static func drawTitle(size: CGSize) -> UIImage {
        let level = Levels.course.first { $0.name == "Reflection" } ?? Levels.course[0]
        let w: CGFloat = 520
        let h = w * max(size.height, 1) / max(size.width, 1)
        // Course top edge ~58% down the screen: logo over the meadow, cups just above the buttons.
        let top = Course.height + CourseArt.borderOut
        let rect = CGRect(x: Course.width / 2 - w / 2, y: top - h * 0.42, width: w, height: h)
        return CourseArt.scenic(level, rect: rect, pixelWidth: size.width * 3)
    }

    // MARK: - Cache

    /// The image saved at `file`, decoded and ready to show; or, if there isn't one, `draw()`'s, saved there.
    nonisolated private static func cached(_ file: URL, _ draw: () -> UIImage) -> UIImage {
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data)?.preparingForDisplay() { return image }
        let image = draw()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: file, options: .atomic)
        return image
    }

    /// This build's folder in Caches. Other builds' folders are cleared out: their art may be out of date.
    nonisolated private static func folder() -> URL {
        let fm = FileManager.default
        let root = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("MenuArt")
        for old in (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] where old.lastPathComponent != buildID {
            try? fm.removeItem(at: old)
        }
        let folder = root.appendingPathComponent(buildID)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// The UUID the linker stamps on the binary this code is in. It changes with any change to the code (art, holes,
    /// an Xcode rebuild after an edit), so cached art always matches the build showing it.
    nonisolated private static let buildID: String = {
        let header = #dsohandle.assumingMemoryBound(to: mach_header_64.self)
        var command = UnsafeRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        for _ in 0..<header.pointee.ncmds {
            let load = command.assumingMemoryBound(to: load_command.self).pointee
            if load.cmd == UInt32(LC_UUID) {
                return UUID(uuid: command.assumingMemoryBound(to: uuid_command.self).pointee.uuid).uuidString
            }
            command = command.advanced(by: Int(load.cmdsize))
        }
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "build"
    }()

    nonisolated private static func fileName(_ name: String) -> String {
        name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? name
    }
}
