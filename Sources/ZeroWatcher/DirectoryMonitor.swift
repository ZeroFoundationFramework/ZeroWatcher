//
//  DirectoryMonitor.swift
//  zero_proj
//
//  Created by Philipp Kotte on 02.07.25.
//
import Foundation

/// Eine Klasse, die ein Verzeichnis auf Dateiänderungen überwacht.
class DirectoryMonitor {
    private var fileSystemEventStream: FSEventStreamRef!
    private let path: String
    private let callback: () -> Void

    init?(path: String, callback: @escaping () -> Void) {
        self.path = path
        self.callback = callback
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (stream, contextInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let contextInfo = contextInfo else { return }
                let mySelf = Unmanaged<DirectoryMonitor>.fromOpaque(contextInfo).takeUnretainedValue()
                mySelf.callback()
            },
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagIgnoreSelf)
        )
        
        guard stream != nil else { return nil }
        self.fileSystemEventStream = stream
    }

    func start() {
        print("👀 [Watcher] Überwache Verzeichnis: \(path)")
        FSEventStreamSetDispatchQueue(fileSystemEventStream, DispatchQueue.main)
        FSEventStreamStart(fileSystemEventStream)
    }

    func stop() {
        FSEventStreamStop(fileSystemEventStream)
    }
}
