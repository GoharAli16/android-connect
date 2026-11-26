import AppKit
import SwiftUI
import ServiceManagement
import CoreImage.CIFilterBuiltins

struct Service {
    let name: String
    let type: String
    let address: String
}
func services(_ text: String) -> [Service] {
    text.split(separator: "\n").compactMap { line in
        let p = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard p.count >= 3, p[1].contains("_adb-tls-") else { return nil }
        return Service(name: p[0], type: p[1], address: p[2])
    }
}
func validAddress(_ text: String) -> Bool {
    guard !text.contains(where: { $0.isWhitespace }), let colon = text.lastIndex(of: ":"), colon != text.startIndex,
          let port = Int(text[text.index(after: colon)...]), (1...65535).contains(port) else { return false }
    return true
}
func connectionMessage(_ output: String) -> String {
    if output.localizedCaseInsensitiveContains("No route to host") {
        return "Mac cannot reach the phone. Check macOS System Settings → Privacy & Security → Local Network access for Android Connect and your ADB host app. Also check Wi-Fi device isolation or VPN. " + output
    }
    if output.contains("protocol fault") {
        return "ADB could not complete pairing. Keep the phone’s QR scanner open and scan a New QR. If this repeats, check Local Network access or restart ADB below. Details: " + output
    }
    return output
}
struct CommandResult { let code: Int32; let output: String }
func command(_ path: String, _ args: [String], input: String? = nil) async -> CommandResult {
    await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .utility).async {
            let process = Process(), pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            process.standardOutput = pipe; process.standardError = pipe
            let stdinPipe = Pipe()
            if input != nil { process.standardInput = stdinPipe }
            do {
                try process.run()
                if let input {
                    stdinPipe.fileHandleForWriting.write(Data((input + "\n").utf8))
                    try? stdinPipe.fileHandleForWriting.close()
                }
                let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
                DispatchQueue.global().asyncAfter(deadline: .now() + 15, execute: timeout)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit(); timeout.cancel()
                continuation.resume(returning: CommandResult(code: process.terminationStatus, output: String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)))
            } catch { continuation.resume(returning: CommandResult(code: -1, output: error.localizedDescription)) }
        }
    }
}
// Bonjour fallback for ADB builds whose own mDNS discovery misses devices.
final class BonjourDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var browsers: [NetServiceBrowser] = []
    private var resolving: [String: NetService] = [:]
    private(set) var found: [String: Service] = [:]
    override init() {
        super.init()
        for type in ["_adb-tls-pairing._tcp.", "_adb-tls-connect._tcp."] {
            let browser = NetServiceBrowser()
            browser.delegate = self
            browsers.append(browser)
            browser.searchForServices(ofType: type, inDomain: "local.")
        }
    }
    private func key(_ service: NetService) -> String { service.name + service.type }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        resolving[key(service)] = service
        service.delegate = self
        service.resolve(withTimeout: 8)
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        found.removeValue(forKey: key(service))
        resolving.removeValue(forKey: key(service))?.stop()
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard sender.port > 0 else { return }
        // Prefer a numeric IPv4 endpoint, matching adb mdns services output.
        for data in sender.addresses ?? [] {
            let host: String? = data.withUnsafeBytes { raw in
                guard let address = raw.baseAddress?.assumingMemoryBound(to: sockaddr.self), address.pointee.sa_family == AF_INET else { return nil }
                var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                guard getnameinfo(address, socklen_t(data.count), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 else { return nil }
                return String(cString: buffer)
            }
            if let host {
                found[key(sender)] = Service(name: sender.name, type: sender.type, address: "\(host):\(sender.port)")
                return
            }
        }
        if let host = sender.hostName {
            found[key(sender)] = Service(name: sender.name, type: sender.type, address: "\(host):\(sender.port)")
        }
    }
}
@MainActor final class Model: ObservableObject {
    @Published var adb = ""
    @Published var message = "Open Wireless debugging on your Android phone."
    @Published var deviceLines: [String] = []
    @Published var nearby: [Service] = []
    @Published var busy = false
    @Published var qr: NSImage?
    @Published var pairingAddress = ""
    @Published var pairingCode = ""
    @Published var connectAddress = ""
    @Published var active = false
    @Published var panelHeight: CGFloat = 580
    private var name = "", password = "", expires = Date.distantPast
    private let bonjour = BonjourDiscovery()
    private var polling = false
    private var attempted = Set<String>()
    private var pendingHost: String?
    init() {
        let saved = UserDefaults.standard.string(forKey: "adbPath")
        let candidates = [saved ?? "", NSHomeDirectory() + "/Library/Android/sdk/platform-tools/adb", "/opt/homebrew/bin/adb", "/usr/local/bin/adb"]
        adb = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? ""
        renew()
        Task { while !Task.isCancelled { if self.active { await self.refresh() }; try? await Task.sleep(for: .seconds(3)) } }
    }
    func renew() {
        name = "studio-" + UUID().uuidString.prefix(10)
        password = (0..<10).map { _ in String(Int.random(in: 0...9)) }.joined()
        expires = Date().addingTimeInterval(300); attempted.removeAll()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data("WIFI:T:ADB;S:\(name);P:\(password);;".utf8)
        filter.correctionLevel = "M"
        if let output = filter.outputImage, let cg = CIContext().createCGImage(output.transformed(by: CGAffineTransform(scaleX: 8, y: 8)), from: output.extent.applying(CGAffineTransform(scaleX: 8, y: 8))) {
            qr = NSImage(cgImage: cg, size: NSSize(width: 220, height: 220))
        }
    }
    func chooseADB() {
        let panel = NSOpenPanel(); panel.message = "Choose the adb executable from Android SDK platform-tools"; panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url, FileManager.default.isExecutableFile(atPath: url.path) {
            adb = url.path; UserDefaults.standard.set(adb, forKey: "adbPath")
        }
    }
    func refresh() async {
        guard !adb.isEmpty, !polling, !busy else { return }
        polling = true; defer { polling = false }
        if Date() >= expires { renew() }
        let found = await command(adb, ["mdns", "services"])
        let all = services(found.output) + Array(bonjour.found.values)
        var seen = Set<String>()
        nearby = all.filter { $0.type.contains("_adb-tls-connect") && seen.insert($0.address).inserted }
        if let match = all.first(where: { $0.name == name && $0.type.contains("_adb-tls-pairing") }), !attempted.contains(match.address) {
            attempted.insert(match.address)
            await pair(match.address, password)
        }
        if let host = pendingHost, let match = nearby.first(where: { $0.address.hasPrefix(host + ":") }) {
            pendingHost = nil; await connect(match.address)
        }
        let result = await command(adb, ["devices", "-l"])
        if result.code == 0 {
            deviceLines = result.output.split(separator: "\n").map(String.init).filter { !$0.hasPrefix("List of devices") && !$0.hasPrefix("*") && !$0.isEmpty }
        } else { message = result.output }
    }
    func pair(_ address: String, _ code: String) async {
        guard validAddress(address), !code.isEmpty, !busy else { return }
        busy = true; message = "Pairing with phone…"
        // Capture only new server-log output, to avoid diagnosing an old failure.
        let status = await command(adb, ["server-status"])
        let logPath = status.output.split(separator: "\n").first(where: { $0.hasPrefix("log_absolute_path:") }).flatMap { line -> String? in
            guard let quote = line.firstIndex(of: "\"") else { return nil }
            return try? JSONDecoder().decode(String.self, from: Data(line[quote...].utf8))
        }
        let log = logPath.flatMap { FileHandle(forReadingAtPath: $0) }
        let offset = (try? log?.seekToEnd()) ?? 0
        let result = await command(adb, ["pair", address], input: code)
        var details = result.output
        if result.code != 0, let log {
            try? log.seek(toOffset: offset)
            let added = String(decoding: (try? log.read(upToCount: 65536)) ?? Data(), as: UTF8.self)
            if added.split(separator: "\n").contains(where: { $0.contains(address) && $0.contains("No route to host") }) {
                details = "Cannot reach \(address): No route to host."
            }
        }
        try? log?.close()
        busy = false
        if result.code == 0 && result.output.contains("Successfully paired") {
            pendingHost = String(address.prefix(upTo: address.lastIndex(of: ":")!))
            pairingCode = ""; message = "Paired. Waiting for the debugging connection…"
            renew()
        } else { message = result.output.isEmpty ? "Pairing timed out. Generate a new QR code and retry." : connectionMessage(details) }
    }
    func restartADB() async {
        guard !busy else { return }
        busy = true
        _ = await command(adb, ["kill-server"])
        let result = await command(adb, ["start-server"])
        busy = false
        if result.code == 0 { renew(); message = "ADB restarted. Allow Local Network access if macOS asks, then scan this new QR." }
        else { message = connectionMessage(result.output) }
    }
    func connect(_ address: String) async {
        guard validAddress(address), !busy else { return }
        busy = true
        let result = await command(adb, ["connect", address]); message = connectionMessage(result.output); busy = false
    }
    func disconnect(_ serial: String) async {
        guard !busy else { return }; busy = true
        let result = await command(adb, ["disconnect", serial]); message = connectionMessage(result.output); busy = false
        await refresh()
    }
}
struct Content: View {
    @ObservedObject var model: Model
    var body: some View {
        ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(.green)
                Text("Android Connect").font(.headline)
                Spacer()
                if model.busy { ProgressView().controlSize(.small) }
                Button { Task { await model.refresh() } } label: { Image(systemName: "arrow.clockwise") }.help("Refresh devices")
            }
            if model.adb.isEmpty {
                Text("ADB is required").font(.title3.bold())
                Text("Install Android SDK Platform-Tools, then choose the adb executable.").foregroundStyle(.secondary)
                Button("Choose ADB…") { model.chooseADB() }
            } else {
                Text("Pair over Wi-Fi").font(.title2.bold())
                Text("On Android 11+: Developer options → Wireless debugging → Pair device with QR code. Keep your phone and Mac on the same Wi-Fi.").font(.callout).foregroundStyle(.secondary)
                HStack { Spacer(); if let qr = model.qr { Image(nsImage: qr).interpolation(.none).resizable().frame(width: 180, height: 180).padding(12).background(.white).clipShape(RoundedRectangle(cornerRadius: 10)) }; Spacer() }
                HStack { Text("QR refreshes every 5 minutes").font(.caption).foregroundStyle(.secondary); Spacer(); Button("New QR") { model.renew() } }.disabled(model.busy)
                Text(model.message).font(.callout).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                DisclosureGroup("Pair with a code instead") {
                    VStack {
                        TextField("Pairing IP:port", text: $model.pairingAddress)
                        SecureField("6-digit pairing code", text: $model.pairingCode)
                        Button("Pair device") { Task { await model.pair(model.pairingAddress, model.pairingCode) } }.disabled(model.busy || !validAddress(model.pairingAddress) || model.pairingCode.count != 6)
                    }.textFieldStyle(.roundedBorder).padding(.top, 6)
                }
                Divider()
                HStack { Text("Devices").font(.headline); Spacer(); Text("\(model.deviceLines.count)").foregroundStyle(.secondary) }
                if model.deviceLines.isEmpty { Text("No devices connected").foregroundStyle(.secondary).font(.callout) }
                ForEach(model.deviceLines, id: \.self) { line in
                    HStack {
                        Image(systemName: "smartphone").foregroundStyle(.green)
                        Text(line.replacingOccurrences(of: "\t", with: "  ")).font(.caption.monospaced()).lineLimit(2).textSelection(.enabled)
                        Spacer()
                        if let serial = line.split(whereSeparator: { $0.isWhitespace }).first, serial.contains(":") || serial.contains("_adb-tls-connect") {
                            Button { Task { await model.disconnect(String(serial)) } } label: { Image(systemName: "xmark.circle") }.help("Disconnect")
                        }
                    }
                }
                if !model.nearby.isEmpty {
                    DisclosureGroup("Available wireless devices") {
                        ForEach(model.nearby, id: \.address) { service in
                            HStack { Text(service.address).font(.caption.monospaced()); Spacer(); Button("Connect") { Task { await model.connect(service.address) } } }
                        }
                    }
                }
                DisclosureGroup("Connect by IP address") {
                    HStack { TextField("Debugging IP:port", text: $model.connectAddress).textFieldStyle(.roundedBorder); Button("Connect") { Task { await model.connect(model.connectAddress) } }.disabled(!validAddress(model.connectAddress) || model.busy) }
                    Text("Use the port on the main Wireless debugging screen, which differs from the pairing port.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            HStack {
                Button("ADB…") { model.chooseADB() }.font(.caption)
                Button("Restart ADB") { Task { await model.restartADB() } }.font(.caption).help("Restarts the shared ADB server and interrupts other debugging sessions")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.font(.caption)
            }
        }.padding(20).frame(maxWidth: .infinity).disabled(model.busy)
        }.frame(width: 390, height: model.panelHeight)
    }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var item: NSStatusItem!
    let popover = NSPopover()
    let model = Model()
    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "Android Connect")
        item.button?.target = self; item.button?.action = #selector(toggle)
        popover.behavior = .transient; popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: Content(model: model))
        if CommandLine.arguments.contains("--show") { toggle() }
    }
    @objc func toggle() {
        if popover.isShown { popover.performClose(nil) } else if let button = item.button {
            let screen = button.window?.screen ?? NSScreen.main
            model.panelHeight = min(580, max(200, (screen?.visibleFrame.height ?? 700) - 60))
            popover.contentSize = NSSize(width: 390, height: model.panelHeight)
            model.active = true
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    func popoverDidClose(_ notification: Notification) { model.active = false }
}
if CommandLine.arguments.contains("--enable-login") {
    do {
        try SMAppService.mainApp.register()
        print("Login item status: \(SMAppService.mainApp.status.rawValue) (1 = enabled, 2 = requires approval)")
    } catch {
        fputs("Could not register login item: \(error)\n", stderr)
        exit(1)
    }
} else if CommandLine.arguments.contains("--login-status") {
    print("Login item status: \(SMAppService.mainApp.status.rawValue) (1 = enabled, 2 = requires approval)")
} else if CommandLine.arguments.contains("--diagnose-mdns") {
    let discovery = BonjourDiscovery()
    RunLoop.current.run(until: Date().addingTimeInterval(5))
    for service in discovery.found.values { print("\(service.name) \(service.type) \(service.address)") }
    print("Bonjour services: \(discovery.found.count)")
} else if CommandLine.arguments.contains("--self-test") {
    let parsed = services("List of discovered mdns services\nADBMenu-abc _adb-tls-pairing._tcp. 192.168.1.2:37001\nadb-phone _adb-tls-connect._tcp. 192.168.1.2:40001\nnoise")
    precondition(parsed.count == 2 && parsed[0].name == "ADBMenu-abc" && parsed[1].address == "192.168.1.2:40001")
    precondition(validAddress("192.168.1.2:5555") && validAddress("[::1]:5555"))
    precondition(!validAddress("host") && !validAddress("host:0") && !validAddress("host:99999") && !validAddress("x y:22"))
    precondition(connectionMessage("error: protocol fault").contains("Keep the phone"))
    precondition(connectionMessage("No route to host").contains("Local Network"))
    print("PASS: mDNS parsing, address validation, pairing error guidance")
} else {
    MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate; app.setActivationPolicy(.accessory); app.run()
    }
}
