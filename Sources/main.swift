import Cocoa
import AVFoundation
import Combine

// MARK: - Folder Model
struct MusicFolder: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    var songs: [Song]
}

// MARK: - Song Model
struct Song: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let title: String
    let duration: TimeInterval
    let fileSize: Int64
    let format: String
    let folderId: UUID
}

// MARK: - Music Player Manager
class MusicPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var folders: [MusicFolder] = []
    @Published var selectedFolderIndex: Int?
    @Published var currentSongIndex: Int?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    var currentSongs: [Song] {
        guard let index = selectedFolderIndex, index < folders.count else {
            return []
        }
        return folders[index].songs
    }
    
    var currentSong: Song? {
        guard let index = currentSongIndex, index < currentSongs.count else { return nil }
        return currentSongs[index]
    }
    
    func addFolders(from urls: [URL]) {
        for url in urls {
            if url.hasDirectoryPath {
                let folderName = url.lastPathComponent
                var folderSongs: [Song] = []
                
                if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                    for file in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                        if isAudioFile(file) {
                            if let song = createSong(from: file, folderId: UUID()) {
                                folderSongs.append(song)
                            }
                        }
                    }
                }
                
                if !folderSongs.isEmpty {
                    let folderId = UUID()
                    let songsWithFolderId = folderSongs.map { song -> Song in
                        Song(url: song.url, title: song.title, duration: song.duration, 
                             fileSize: song.fileSize, format: song.format, folderId: folderId)
                    }
                    let folder = MusicFolder(url: url, name: folderName, songs: songsWithFolderId)
                    folders.append(folder)
                }
            }
        }
        
        // 如果没有选中文件夹，自动选中第一个
        if selectedFolderIndex == nil && !folders.isEmpty {
            selectedFolderIndex = 0
        }
    }
    
    func removeFolder(at index: Int) {
        guard index < folders.count else { return }
        
        // 如果正在播放该文件夹的歌曲，停止播放
        if let currentIndex = currentSongIndex,
           let selectedFolder = selectedFolderIndex,
           selectedFolder == index {
            player?.stop()
            player = nil
            isPlaying = false
            currentSongIndex = nil
            stopTimer()
        }
        
        folders.remove(at: index)
        
        // 调整选中索引
        if folders.isEmpty {
            selectedFolderIndex = nil
        } else if let selected = selectedFolderIndex {
            if selected >= folders.count {
                selectedFolderIndex = folders.count - 1
            }
        }
    }
    
    private func isAudioFile(_ url: URL) -> Bool {
        let audioExtensions = ["mp3", "m4a", "aac", "wav", "aiff", "flac", "ogg", "wma"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func createSong(from url: URL, folderId: UUID) -> Song? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else { return nil }
        
        let asset = AVAsset(url: url)
        let duration = asset.duration.seconds.isFinite ? asset.duration.seconds : 0
        let title = url.deletingPathExtension().lastPathComponent
        let format = url.pathExtension.uppercased()
        
        return Song(url: url, title: title, duration: duration, fileSize: fileSize, format: format, folderId: folderId)
    }
    
    func play(at index: Int) {
        guard index < currentSongs.count else { return }
        
        currentSongIndex = index
        let song = currentSongs[index]
        
        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: song.url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            startTimer()
        } catch {
            print("Error playing song: \(error)")
        }
    }
    
    func playPause() {
        guard player != nil else {
            if !currentSongs.isEmpty {
                play(at: 0)
            }
            return
        }
        
        if isPlaying {
            player?.pause()
            isPlaying = false
            stopTimer()
        } else {
            player?.play()
            isPlaying = true
            startTimer()
        }
    }
    
    func playNext() {
        guard let current = currentSongIndex else { return }
        let next = (current + 1) % currentSongs.count
        play(at: next)
    }
    
    func deleteSong(at index: Int) {
        guard let selectedFolder = selectedFolderIndex,
              selectedFolder < folders.count,
              index < folders[selectedFolder].songs.count else { return }
        
        // 如果正在播放这首歌，先停止
        if currentSongIndex == index {
            player?.stop()
            player = nil
            isPlaying = false
            currentSongIndex = nil
            stopTimer()
        } else if let current = currentSongIndex, current > index {
            // 如果删除的是当前播放歌曲之前的歌曲，调整索引
            currentSongIndex = current - 1
        }
        
        // 从数组中移除
        folders[selectedFolder].songs.remove(at: index)
        
        // 如果文件夹空了，删除文件夹
        if folders[selectedFolder].songs.isEmpty {
            removeFolder(at: selectedFolder)
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.currentTime = self?.player?.currentTime ?? 0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNext()
    }
}

// MARK: - Folder Cell View
class FolderCellView: NSTableCellView {
    let textLabel = NSTextField()
    let iconView = NSImageView()
    let countLabel = NSTextField()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        iconView.contentTintColor = .systemYellow
        addSubview(iconView)
        
        // Text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.isEditable = false
        textLabel.isBordered = false
        textLabel.backgroundColor = .clear
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.font = NSFont.systemFont(ofSize: 13)
        addSubview(textLabel)
        
        // Count label
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.isEditable = false
        countLabel.isBordered = false
        countLabel.backgroundColor = .clear
        countLabel.font = NSFont.systemFont(ofSize: 11)
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .right
        addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            
            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            countLabel.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }
    
    func configure(with folder: MusicFolder, isSelected: Bool) {
        textLabel.stringValue = folder.name
        // 选中时加粗字体
        textLabel.font = isSelected ? NSFont.systemFont(ofSize: 13, weight: .semibold) : NSFont.systemFont(ofSize: 13)
        countLabel.stringValue = "\(folder.songs.count)"
        countLabel.font = isSelected ? NSFont.systemFont(ofSize: 11, weight: .medium) : NSFont.systemFont(ofSize: 11)
        countLabel.textColor = .secondaryLabelColor
        iconView.contentTintColor = .systemYellow
    }
}

// MARK: - Song Cell View
class SongCellView: NSTableCellView {
    let textLabel = NSTextField()
    let playingIndicator = NSImageView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isTitleColumn = false
    
    private func setupUI() {
        // Playing indicator (only for title column)
        playingIndicator.translatesAutoresizingMaskIntoConstraints = false
        playingIndicator.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: nil)
        playingIndicator.contentTintColor = .systemBlue
        addSubview(playingIndicator)
        
        // Text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.isEditable = false
        textLabel.isBordered = false
        textLabel.backgroundColor = .clear
        textLabel.lineBreakMode = .byTruncatingTail
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            playingIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            playingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            playingIndicator.widthAnchor.constraint(equalToConstant: 16),
            playingIndicator.heightAnchor.constraint(equalToConstant: 16),
            
            textLabel.leadingAnchor.constraint(equalTo: playingIndicator.trailingAnchor, constant: 4),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    func setupForColumn(_ columnIdentifier: String) {
        isTitleColumn = (columnIdentifier == "title")
        
        // Remove old constraints
        textLabel.removeFromSuperview()
        playingIndicator.removeFromSuperview()
        
        if isTitleColumn {
            // Title column: has playing indicator
            addSubview(playingIndicator)
            addSubview(textLabel)
            
            NSLayoutConstraint.activate([
                playingIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                playingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
                playingIndicator.widthAnchor.constraint(equalToConstant: 16),
                playingIndicator.heightAnchor.constraint(equalToConstant: 16),
                
                textLabel.leadingAnchor.constraint(equalTo: playingIndicator.trailingAnchor, constant: 4),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        } else {
            // Other columns: consistent left margin
            addSubview(textLabel)
            
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        }
    }
    
    func configure(with song: Song, isPlaying: Bool, columnIdentifier: String) {
        playingIndicator.isHidden = true
        
        switch columnIdentifier {
        case "title":
            textLabel.stringValue = song.title
            textLabel.textColor = isPlaying ? .systemBlue : .labelColor
            textLabel.font = NSFont.systemFont(ofSize: 13)
            textLabel.alignment = .left
            playingIndicator.isHidden = !isPlaying
        case "duration":
            let minutes = Int(song.duration) / 60
            let seconds = Int(song.duration) % 60
            textLabel.stringValue = String(format: "%d:%02d", minutes, seconds)
            textLabel.textColor = .secondaryLabelColor
            textLabel.font = NSFont.systemFont(ofSize: 12)
            textLabel.alignment = .left
        case "size":
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            textLabel.stringValue = formatter.string(fromByteCount: song.fileSize)
            textLabel.textColor = .secondaryLabelColor
            textLabel.font = NSFont.systemFont(ofSize: 12)
            textLabel.alignment = .left
        case "format":
            textLabel.stringValue = song.format
            textLabel.textColor = .secondaryLabelColor
            textLabel.font = NSFont.systemFont(ofSize: 12)
            textLabel.alignment = .left
        default:
            textLabel.stringValue = ""
        }
    }
}

// MARK: - Drop View
class DropView: NSView {
    var onDrop: (([URL]) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            onDrop?(urls)
            return true
        }
        
        return false
    }
}

// MARK: - Main Window Controller
class MainWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    let playerManager = MusicPlayerManager()
    var splitView: NSSplitView!
    var folderTableView: NSTableView!
    var songTableView: NSTableView!
    var playButton: NSButton!
    var infoLabel: NSTextField!
    var timeLabel: NSTextField!
    var dropView: DropView!
    
    var titleColumn: NSTableColumn!
    var durationColumn: NSTableColumn!
    var sizeColumn: NSTableColumn!
    var formatColumn: NSTableColumn!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupWindow()
        setupUI()
        setupBindings()
    }
    
    private func setupWindow() {
        window?.title = "Easylove"
        window?.minSize = NSSize(width: 700, height: 400)
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Drop view
        dropView = DropView()
        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.onDrop = { [weak self] urls in
            self?.playerManager.addFolders(from: urls)
        }
        contentView.addSubview(dropView)
        
        // Header view
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        dropView.addSubview(headerView)
        
        // Play button
        playButton = NSButton()
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.bezelStyle = .circular
        playButton.image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: nil)
        playButton.imagePosition = .imageOnly
        playButton.imageScaling = .scaleProportionallyUpOrDown
        playButton.contentTintColor = .systemBlue
        playButton.target = self
        playButton.action = #selector(playPauseClicked)
        headerView.addSubview(playButton)
        
        // Info label
        infoLabel = NSTextField()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.isEditable = false
        infoLabel.isBordered = false
        infoLabel.backgroundColor = .clear
        infoLabel.stringValue = "拖放音乐文件夹到这里"
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.font = NSFont.systemFont(ofSize: 13)
        headerView.addSubview(infoLabel)
        
        // Time label
        timeLabel = NSTextField()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.isEditable = false
        timeLabel.isBordered = false
        timeLabel.backgroundColor = .clear
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.font = NSFont.systemFont(ofSize: 11)
        headerView.addSubview(timeLabel)
        
        // Main container using stack view
        let mainStackView = NSStackView()
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.orientation = .horizontal
        mainStackView.spacing = 0
        mainStackView.distribution = .fill
        dropView.addSubview(mainStackView)
        
        // Folder list (left side) - fixed width
        let folderContainer = NSView()
        folderContainer.translatesAutoresizingMaskIntoConstraints = false
        folderContainer.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        let folderScrollView = NSScrollView()
        folderScrollView.translatesAutoresizingMaskIntoConstraints = false
        folderScrollView.hasVerticalScroller = true
        folderScrollView.autohidesScrollers = true
        folderScrollView.borderType = .noBorder
        folderContainer.addSubview(folderScrollView)
        
        NSLayoutConstraint.activate([
            folderScrollView.topAnchor.constraint(equalTo: folderContainer.topAnchor),
            folderScrollView.leadingAnchor.constraint(equalTo: folderContainer.leadingAnchor),
            folderScrollView.trailingAnchor.constraint(equalTo: folderContainer.trailingAnchor),
            folderScrollView.bottomAnchor.constraint(equalTo: folderContainer.bottomAnchor)
        ])
        
        folderTableView = NSTableView()
        folderTableView.rowHeight = 32
        folderTableView.selectionHighlightStyle = .none
        folderTableView.allowsMultipleSelection = false
        folderTableView.allowsEmptySelection = true
        folderTableView.dataSource = self
        folderTableView.delegate = self
        folderTableView.action = #selector(folderTableViewClicked)
        folderTableView.headerView = nil
        
        let folderColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("folder"))
        folderColumn.width = 180
        folderColumn.minWidth = 120
        folderColumn.maxWidth = 300
        folderTableView.addTableColumn(folderColumn)
        
        folderScrollView.documentView = folderTableView
        folderTableView.frame = NSRect(x: 0, y: 0, width: 200, height: 400)
        
        mainStackView.addArrangedSubview(folderContainer)
        
        // Divider - match table header separator color
        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.gridColor.cgColor
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        mainStackView.addArrangedSubview(divider)
        
        // Song list (right side) - fill remaining
        let songScrollView = NSScrollView()
        songScrollView.translatesAutoresizingMaskIntoConstraints = false
        songScrollView.hasVerticalScroller = true
        songScrollView.autohidesScrollers = true
        songScrollView.borderType = .noBorder
        
        songTableView = NSTableView()
        songTableView.translatesAutoresizingMaskIntoConstraints = false
        songTableView.rowHeight = 28
        songTableView.selectionHighlightStyle = .none
        songTableView.allowsMultipleSelection = false
        songTableView.dataSource = self
        songTableView.delegate = self
        songTableView.target = self
        songTableView.action = #selector(songTableViewClicked)
        songTableView.doubleAction = #selector(songTableViewDoubleClicked)
        songTableView.allowsColumnResizing = true
        songTableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle
        
        titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleColumn.title = "名称"
        titleColumn.width = 300
        titleColumn.minWidth = 150
        titleColumn.maxWidth = 1000
        titleColumn.resizingMask = .autoresizingMask
        songTableView.addTableColumn(titleColumn)
        
        sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeColumn.title = "大小"
        sizeColumn.width = 70
        sizeColumn.minWidth = 50
        sizeColumn.maxWidth = 120
        sizeColumn.resizingMask = .userResizingMask
        songTableView.addTableColumn(sizeColumn)
        
        durationColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("duration"))
        durationColumn.title = "时长"
        durationColumn.width = 60
        durationColumn.minWidth = 45
        durationColumn.maxWidth = 80
        durationColumn.resizingMask = .userResizingMask
        songTableView.addTableColumn(durationColumn)
        
        formatColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("format"))
        formatColumn.title = "格式"
        formatColumn.width = 50
        formatColumn.minWidth = 40
        formatColumn.maxWidth = 70
        formatColumn.resizingMask = .userResizingMask
        songTableView.addTableColumn(formatColumn)
        
        songTableView.headerView = NSTableHeaderView()
        songScrollView.documentView = songTableView
        songTableView.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        songTableView.autoresizingMask = [.width, .height]
        
        mainStackView.addArrangedSubview(songScrollView)
        
        // Constraints
        NSLayoutConstraint.activate([
            dropView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dropView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dropView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: dropView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            playButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            playButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 36),
            playButton.heightAnchor.constraint(equalToConstant: 36),
            
            infoLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
            infoLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -12),
            
            timeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            timeLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: dropView.bottomAnchor)
        ])
        
        // Setup context menus
        setupFolderContextMenu()
        setupSongContextMenu()
    }
    
    private func setupFolderContextMenu() {
        let menu = NSMenu()
        
        let removeItem = NSMenuItem(title: "移除文件夹", action: #selector(removeFolder), keyEquivalent: "")
        removeItem.target = self
        menu.addItem(removeItem)
        
        let showInFinderItem = NSMenuItem(title: "在 Finder 中显示", action: #selector(showFolderInFinder), keyEquivalent: "")
        showInFinderItem.target = self
        menu.addItem(showInFinderItem)
        
        folderTableView.menu = menu
    }
    
    private func setupSongContextMenu() {
        let menu = NSMenu()
        
        let showInFinderItem = NSMenuItem(title: "在 Finder 中显示", action: #selector(showSongInFinder), keyEquivalent: "")
        showInFinderItem.target = self
        menu.addItem(showInFinderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let deleteItem = NSMenuItem(title: "从列表中移除", action: #selector(removeFromList), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        
        let deleteFileItem = NSMenuItem(title: "移到废纸篓", action: #selector(moveToTrash), keyEquivalent: "")
        deleteFileItem.target = self
        menu.addItem(deleteFileItem)
        
        songTableView.menu = menu
    }
    
    @objc private func folderTableViewClicked() {
        let clickedRow = folderTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.folders.count else { return }
        
        // 停止当前播放
        if playerManager.isPlaying {
            playerManager.playPause()
        }
        playerManager.currentSongIndex = nil
        
        // 更新选中状态
        let previousIndex = playerManager.selectedFolderIndex
        playerManager.selectedFolderIndex = clickedRow
        
        // 刷新之前和当前选中的行（为了更新加粗效果）
        if let previous = previousIndex, previous != clickedRow {
            folderTableView.reloadData(forRowIndexes: IndexSet([previous, clickedRow]), columnIndexes: IndexSet(integer: 0))
        } else {
            folderTableView.reloadData(forRowIndexes: IndexSet(integer: clickedRow), columnIndexes: IndexSet(integer: 0))
        }
        
        // 刷新歌曲列表
        songTableView.reloadData()
    }
    
    @objc private func removeFolder() {
        let clickedRow = folderTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.folders.count else { return }
        
        playerManager.removeFolder(at: clickedRow)
    }
    
    @objc private func showFolderInFinder() {
        let clickedRow = folderTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.folders.count else { return }
        
        let folder = playerManager.folders[clickedRow]
        NSWorkspace.shared.activateFileViewerSelecting([folder.url])
    }
    
    @objc private func showSongInFinder() {
        let clickedRow = songTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.currentSongs.count else { return }
        
        let song = playerManager.currentSongs[clickedRow]
        NSWorkspace.shared.activateFileViewerSelecting([song.url])
    }
    
    @objc private func removeFromList() {
        let clickedRow = songTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.currentSongs.count else { return }
        
        playerManager.deleteSong(at: clickedRow)
    }
    
    @objc private func moveToTrash() {
        let clickedRow = songTableView.clickedRow
        guard clickedRow >= 0, clickedRow < playerManager.currentSongs.count else { return }
        
        let song = playerManager.currentSongs[clickedRow]
        
        do {
            try FileManager.default.trashItem(at: song.url, resultingItemURL: nil)
            playerManager.deleteSong(at: clickedRow)
        } catch {
            let alert = NSAlert()
            alert.messageText = "无法删除文件"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    private func setupBindings() {
        playerManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    private func updateUI() {
        folderTableView.reloadData()
        songTableView.reloadData()
        
        if let currentSong = playerManager.currentSong {
            infoLabel.stringValue = currentSong.title
            infoLabel.textColor = .labelColor
            let currentMin = Int(playerManager.currentTime) / 60
            let currentSec = Int(playerManager.currentTime) % 60
            let totalMin = Int(currentSong.duration) / 60
            let totalSec = Int(currentSong.duration) % 60
            timeLabel.stringValue = String(format: "%d:%02d / %d:%02d", currentMin, currentSec, totalMin, totalSec)
        } else {
            if playerManager.folders.isEmpty {
                infoLabel.stringValue = "拖放音乐文件夹到这里"
            } else if playerManager.selectedFolderIndex == nil {
                infoLabel.stringValue = "选择左侧文件夹"
            } else {
                infoLabel.stringValue = "点击播放"
            }
            infoLabel.textColor = .secondaryLabelColor
            timeLabel.stringValue = ""
        }
        
        let imageName = playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playButton.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        playButton.contentTintColor = .systemBlue
        playButton.isEnabled = !playerManager.currentSongs.isEmpty
        

    }
    
    @objc private func playPauseClicked() {
        playerManager.playPause()
    }
    
    @objc private func songTableViewClicked() {
        let clickedRow = songTableView.clickedRow
        guard clickedRow >= 0 else { return }
        
        if playerManager.currentSongIndex == clickedRow {
            playerManager.playPause()
        } else {
            playerManager.play(at: clickedRow)
        }
    }
    
    @objc private func songTableViewDoubleClicked() {
        let clickedRow = songTableView.clickedRow
        guard clickedRow >= 0 else { return }
        playerManager.play(at: clickedRow)
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == folderTableView {
            return playerManager.folders.count
        } else {
            return playerManager.currentSongs.count
        }
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == folderTableView {
            let cell = FolderCellView()
            let folder = playerManager.folders[row]
            let isSelected = playerManager.selectedFolderIndex == row
            cell.configure(with: folder, isSelected: isSelected)
            return cell
        } else {
            let cell = SongCellView()
            let song = playerManager.currentSongs[row]
            let isPlaying = playerManager.currentSongIndex == row && playerManager.isPlaying
            let columnId = tableColumn?.identifier.rawValue ?? ""
            cell.setupForColumn(columnId)
            cell.configure(with: song, isPlaying: isPlaying, columnIdentifier: columnId)
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if tableView == folderTableView {
            // 文件夹列表：无背景，只靠文字加粗区分
            return NSTableRowView()
        } else {
            // 歌曲列表使用自定义高亮
            let rowView = NSTableRowView()
            if playerManager.currentSongIndex == row {
                rowView.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3)
            }
            return rowView
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == folderTableView {
            return 32
        } else {
            return 28
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        
        windowController = MainWindowController(window: window)
        windowController.windowDidLoad()
        windowController.showWindow(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
