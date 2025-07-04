//
//  ProcessRunner.swift
//  zero_proj
//
//  Created by Philipp Kotte on 02.07.25.
//

import Foundation
import ZeroLogger

/// Eine Klasse, die einen Prozess (wie deinen Server) verwaltet.
public class ProcessRunner {
    private var process: Process?
    private let executable: String
    private var logger = Logger(label: "zero.watcher.process")

    init(executable: String) {
        self.executable = executable
    }

    /// Startet den Kompilierungs- und Ausführungsprozess.
    func start() {
        logger.dev("🚀 [Watcher] Kompiliere und starte `\(executable)`...")
        
        let buildProcess = Process()
        buildProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        buildProcess.arguments = ["build", "--product", executable]
        
        do {
            try buildProcess.run()
            buildProcess.waitUntilExit()
        } catch {
            logger.error("❌ [Watcher] Fehler beim Kompilieren: \(error)")
            return
        }

        guard buildProcess.terminationStatus == 0 else {
            logger.error("❌ [Watcher] Kompilierung fehlgeschlagen. Warte auf die nächste Änderung.")
            return
        }
        
        logger.dev("✅ [Watcher] Kompilierung erfolgreich. Starte den Server...")

        let pathProcess = Process()
        pathProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        pathProcess.arguments = ["build", "--show-bin-path"]
        
        let pipe = Pipe()
        pathProcess.standardOutput = pipe
        
        do {
            try pathProcess.run()
            pathProcess.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let executablePath = "\(path)/\(executable)"
                
                process = Process()
                process?.executableURL = URL(fileURLWithPath: executablePath)
                try process?.run()
                logger.dev("✅ [Watcher] Server mit PID \(process?.processIdentifier ?? -1) läuft.")
            }
        } catch {
            print("❌ [Watcher] Server konnte nicht gestartet werden: \(error)")
        }
    }

    /// Stoppt den laufenden Serverprozess auf eine robuste Weise.
    func stop() {
        guard let process = process, process.isRunning else { return }
        logger.error("🛑 [Watcher] Stoppe Serverprozess (PID \(process.processIdentifier))...")

        // 1. Sende ein "sanftes" Interrupt-Signal (wie Ctrl+C).
        // Das gibt dem Server die Chance, sich selbst sauber zu beenden (Graceful Shutdown).
        process.interrupt()
        
        // 2. Warte bis zu 2 Sekunden, ob der Prozess von selbst endet.
        let deadline = Date(timeIntervalSinceNow: 2.0)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        // 3. Wenn der Prozess immer noch läuft, beende ihn zwangsweise.
        if process.isRunning {
            logger.warning("⚠️ [Watcher] Prozess reagiert nicht, erzwinge Beendigung...")
            process.terminate() // Sendet SIGTERM
            process.waitUntilExit() // Warte jetzt auf den erzwungenen Exit.
        }
        
        logger.dev("✅ [Watcher] Prozess beendet.")
        self.process = nil
    }
}
