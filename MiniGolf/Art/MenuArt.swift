import MachO
import Observation
import SwiftUI

/// Menu artwork: every hole's card and the title's backdrop. They take seconds to draw, so the loading screen draws
/// them once per build, saves them to Caches, and loads them from there on later launches. The menus only ever show
/// art that's ready, so they never draw while you scroll.
@MainActor
@Observable
final class MenuArt {
    static let shared = MenuArt()
    @ObservationIgnored private var cards: [String: UIImage] = [:]
    /// Title backdrops by screen size (see `titleKey`): the few most recently shown, oldest first in `titleOrder`.
    private var titles: [String: UIImage] = [:]
    @ObservationIgnored private var titleOrder: [String] = []
    /// A backdrop is a full screen of pixels (some 20 MB on an iPad), so only this many are kept in memory; the rest
    /// stay in the cache on disk.
    private static let titlesKept = 3
    /// The size the title screen is waiting on, and the wait-then-draw for it.
    @ObservationIgnored private var wantedTitle: String?
    @ObservationIgnored private var titleTask: Task<Void, Never>?

    /// A hole's card, once `prepare` has run.
    func card(_ level: Level) -> UIImage? { cards[level.name] }

    /// The title's backdrop for a screen of `size` at `scale`. A size it hasn't got (an iPad turned or resized, a Duo
    /// opened) is drawn in the background, or loaded from the cache, once the size has settled; until then the
    /// backdrop of the nearest shape stands in, filled to the screen.
    func title(size: CGSize, scale: CGFloat) -> UIImage? {
        let key = Self.titleKey(size)
        if let image = titles[key] {
            titleOrder.removeAll { $0 == key }
            titleOrder.append(key)
            return image
        }
        if wantedTitle != key {
            wantedTitle = key
            titleTask?.cancel()
            let file = Self.folder().appendingPathComponent("title-\(key).jpg")
            titleTask = Task {
                // A window being resized passes through many sizes: only draw the one it stops at.
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                let image = await Task.detached(priority: .userInitiated) {
                    Self.cached(file) { Self.drawTitle(size: size, scale: scale) }
                }.value
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.4)) { self.keepTitle(image, key) }
                self.wantedTitle = nil
            }
        }
        let aspect = size.height / max(size.width, 1)
        return titles.values.min { abs($0.size.height / $0.size.width - aspect) < abs($1.size.height / $1.size.width - aspect) }
    }

    private func keepTitle(_ image: UIImage, _ key: String) {
        titles[key] = image
        titleOrder.removeAll { $0 == key }
        titleOrder.append(key)
        while titleOrder.count > Self.titlesKept { titles[titleOrder.removeFirst()] = nil }
    }

    nonisolated private static func titleKey(_ size: CGSize) -> String { "\(Int(size.width))x\(Int(size.height))" }

    /// Load the title and every hole's card from the cache, drawing (and saving) any that aren't there yet, several
    /// at once. `progress` hears the share done after each one.
    func prepare(_ levels: [Level], screen: CGSize, scale: CGFloat, progress: @escaping (Double) -> Void) async {
        let folder = Self.folder()
        // A touch wider than Free Play's cards (see CourseRow), so they stay crisp; an iPad's the wider of its two ways
        // round.
        let widths = [screen.width, screen.height].prefix(UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
        let cardWidth = (widths.map { CourseRow.cardWidth(in: $0) }.max()! * 1.05 * scale).rounded(.up)
        // An iPad turns, so it gets the title for the other way round too.
        var screens = [screen]
        if UIDevice.current.userInterfaceIdiom == .pad { screens.append(CGSize(width: screen.height, height: screen.width)) }
        // The titles first: they take the longest. Their names are their sizes' keys.
        let jobs: [(name: String, title: Bool, file: URL, draw: () -> UIImage)] =
            screens.map { size in
                (Self.titleKey(size), true, folder.appendingPathComponent("title-\(Self.titleKey(size)).jpg"), { Self.drawTitle(size: size, scale: scale) })
            }
            + levels.map { level in
                (level.name, false, folder.appendingPathComponent("card-\(Self.fileName(level.name))-\(Int(cardWidth)).jpg"),
                 { CourseArt.card(level, pixelWidth: cardWidth) })
            }
        await withTaskGroup(of: (String, Bool, UIImage).self) { group in
            // One short of a job per core: with every thread drawing, the progress updates (and the rest of the app's
            // async work) would wait for the drawing to finish.
            var queue = jobs.makeIterator()
            func start() {
                guard let job = queue.next() else { return }
                group.addTask { (job.name, job.title, Self.cached(job.file, job.draw)) }
            }
            for _ in 0..<max(1, ProcessInfo.processInfo.activeProcessorCount - 1) { start() }
            var done = 0
            for await (name, title, image) in group {
                if title { keepTitle(image, name) } else { cards[name] = image }
                done += 1
                progress(Double(done) / Double(jobs.count))
                start()
            }
        }
    }

    nonisolated private static func drawTitle(size: CGSize, scale: CGFloat) -> UIImage {
        let level = Levels.course.first { $0.name == "Reflection" } ?? Levels.course[0]
        // At least 520 units across; on a wide screen, enough for 600 down, so the course isn't blown up to fill it.
        let aspect = max(size.height, 1) / max(size.width, 1)
        let w = max(520, 600 / aspect)
        let h = w * aspect
        // Course top edge ~58% down the screen: logo over the meadow, cups just above the buttons.
        let top = Course.height + CourseArt.borderOut
        let rect = CGRect(x: Course.width / 2 - w / 2, y: top - h * 0.42, width: w, height: h)
        return CourseArt.scenic(level, rect: rect, pixelWidth: size.width * scale)
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
