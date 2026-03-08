import Cocoa

// MARK: - Window Controller

class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "GoToFolder — Settings"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.contentViewController = SettingsViewController()
    }
}

// MARK: - View Controller

class SettingsViewController: NSViewController {

    // MARK: Subviews

    private let iconLabel: NSTextField = {
        let f = NSTextField(labelWithString: ">_<")
        f.font = NSFont.monospacedSystemFont(ofSize: 48, weight: .bold)
        f.textColor = .labelColor
        f.alignment = .center
        return f
    }()

    private let titleLabel: NSTextField = {
        let f = NSTextField(labelWithString: "GoToFolder")
        f.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        f.textColor = .labelColor
        f.alignment = .center
        return f
    }()

    private let subtitleLabel: NSTextField = {
        let f = NSTextField(labelWithString: "Open terminal at current Finder folder")
        f.font = NSFont.systemFont(ofSize: 12)
        f.textColor = .secondaryLabelColor
        f.alignment = .center
        return f
    }()

    private let terminalLabel: NSTextField = {
        let f = NSTextField(labelWithString: "Terminal app:")
        f.font = NSFont.systemFont(ofSize: 13)
        f.textColor = .labelColor
        f.alignment = .right
        return f
    }()

    private let terminalPopup: NSPopUpButton = {
        let p = NSPopUpButton(frame: .zero, pullsDown: false)
        Terminal.allCases.forEach { p.addItem(withTitle: $0.displayName) }
        return p
    }()

    private let divider: NSBox = {
        let b = NSBox()
        b.boxType = .separator
        return b
    }()

    private let instructionsTitle: NSTextField = {
        let f = NSTextField(labelWithString: "How to add to Finder toolbar")
        f.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        f.textColor = .labelColor
        return f
    }()

    private let instructionsBody: NSTextField = {
        let steps = """
        1. Copy GoToFolder.app to /Applications
        2. Open a Finder window
        3. Hold ⌘ Command and drag GoToFolder.app into the Finder toolbar
        4. Click the >_< button to open the terminal at that folder
        """
        let f = NSTextField(wrappingLabelWithString: steps)
        f.font = NSFont.systemFont(ofSize: 11.5)
        f.textColor = .secondaryLabelColor
        return f
    }()

    private let saveButton: NSButton = {
        let b = NSButton(title: "Save", target: nil, action: nil)
        b.bezelStyle = .rounded
        b.keyEquivalent = "\r"
        return b
    }()

    private let testButton: NSButton = {
        let b = NSButton(title: "Test Now", target: nil, action: nil)
        b.bezelStyle = .rounded
        return b
    }()

    // MARK: Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 340))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        loadPreferences()

        saveButton.target = self
        saveButton.action = #selector(save)
        testButton.target = self
        testButton.action = #selector(test)
    }

    // MARK: Layout

    private func buildLayout() {
        let views: [NSView] = [
            iconLabel, titleLabel, subtitleLabel,
            terminalLabel, terminalPopup,
            divider,
            instructionsTitle, instructionsBody,
            saveButton, testButton
        ]
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let m: CGFloat = 24

        NSLayoutConstraint.activate([
            // Icon + title block
            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: m),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 4),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            // Terminal selector row
            terminalLabel.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            terminalLabel.centerYAnchor.constraint(equalTo: terminalPopup.centerYAnchor),
            terminalLabel.widthAnchor.constraint(equalToConstant: 110),

            terminalPopup.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            terminalPopup.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            terminalPopup.widthAnchor.constraint(equalToConstant: 160),

            // Divider
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: m),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -m),
            divider.topAnchor.constraint(equalTo: terminalPopup.bottomAnchor, constant: 20),

            // Instructions
            instructionsTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: m),
            instructionsTitle.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),

            instructionsBody.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: m),
            instructionsBody.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -m),
            instructionsBody.topAnchor.constraint(equalTo: instructionsTitle.bottomAnchor, constant: 6),

            // Buttons
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -m),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -m),
            saveButton.widthAnchor.constraint(equalToConstant: 90),

            testButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -10),
            testButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -m),
            testButton.widthAnchor.constraint(equalToConstant: 90),
        ])
    }

    // MARK: Actions

    private func loadPreferences() {
        let saved = UserDefaults.standard.string(forKey: Terminal.defaultsKey) ?? Terminal.terminal.rawValue
        if let idx = Terminal.allCases.firstIndex(where: { $0.rawValue == saved }) {
            terminalPopup.selectItem(at: idx)
        }
    }

    @objc private func save() {
        let selected = Terminal.allCases[terminalPopup.indexOfSelectedItem]
        UserDefaults.standard.set(selected.rawValue, forKey: Terminal.defaultsKey)
        view.window?.close()
    }

    @objc private func test() {
        let selected = Terminal.allCases[terminalPopup.indexOfSelectedItem]
        UserDefaults.standard.set(selected.rawValue, forKey: Terminal.defaultsKey)

        if let path = FinderBridge.currentPath() {
            TerminalLauncher.open(path: path)
        } else {
            // No Finder window open — use home directory as fallback
            TerminalLauncher.open(path: NSHomeDirectory())
        }
    }
}
