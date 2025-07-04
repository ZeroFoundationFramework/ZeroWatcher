// In Sources/watch/main.swift
//
// Ein Hot-Reload-Skript für serverseitige Swift-Frameworks.
// ANLEITUNG:
// 1. Stelle sicher, dass deine Ordnerstruktur und Package.swift korrekt sind.
// 2. Passe die `configuration`-Variablen unten an (falls nötig).
// 3. Starte den Watcher aus dem Terminal: `swift run watch`
// 4. Beginne mit der Entwicklung! Bei jeder Änderung wird der Server neu gestartet.

import Foundation
import CoreServices


// --- Konfiguration ---
let configuration = (
    // Der Name deines Executable-Produkts, wie in Package.swift definiert.
    executable: "App", // <-- Sollte mit dem Namen deines App-Targets übereinstimmen
    // Das Verzeichnis, das auf Änderungen überwacht werden soll.
    watchPath: "./Sources"
)

// --- Hauptlogik des Watchers ---

let runner = ProcessRunner(executable: configuration.executable)
var debounceTimer: Timer?

let monitor = DirectoryMonitor(path: configuration.watchPath) {
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        // Führe die Aktionen auf dem Main-Actor aus, um Concurrency-Fehler zu vermeiden.
        DispatchQueue.main.async {
            print("\n🔄 [Watcher] Dateiänderung erkannt!")
            runner.stop()
            runner.start()
        }
    }
}

if let monitor = monitor {
    monitor.start()
    runner.start()
    RunLoop.main.run()
} else {
    print("❌ [Watcher] konnte nicht gestartet werden.")
}
