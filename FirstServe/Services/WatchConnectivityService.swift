//
//  WatchConnectivityService.swift
//  FirstServe
//
//  Manages WatchConnectivity session on the iOS side.
//  Sends active match data to the Watch and processes
//  scoring commands received from the Watch.
//

import Foundation
import WatchConnectivity
import SwiftData

@Observable
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    var isWatchReachable = false

    private var modelContext: ModelContext?
    /// Cached ViewModels keyed by match UUID string so undo stacks persist.
    private var activeViewModels: [String: MatchViewModel] = [:]
    /// When true, sendMatchUpdate is suppressed — the Watch command reply handles it.
    private var isProcessingWatchCommand = false

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func configure(context: ModelContext) {
        self.modelContext = context
        guard WCSession.isSupported() else {
            print("[WatchSync] WCSession not supported")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        print("[WatchSync] WCSession activating...")
    }

    // MARK: - Push active match list to Watch

    func sendActiveMatches(_ matches: [Match]) {
        guard WCSession.default.activationState == .activated else {
            print("[WatchSync] sendActiveMatches: session not activated")
            return
        }

        let watchMatches = matches
            .filter { !$0.isComplete }
            .map { buildWatchMatchState(from: $0) }

        print("[WatchSync] sendActiveMatches: \(watchMatches.count) active matches, reachable=\(WCSession.default.isReachable)")

        guard let data = try? JSONEncoder().encode(watchMatches),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            print("[WatchSync] sendActiveMatches: encoding failed")
            return
        }

        do {
            try WCSession.default.updateApplicationContext([
                "type": "activeMatches",
                "matches": json
            ])
            print("[WatchSync] sendActiveMatches: applicationContext updated OK")
        } catch {
            print("[WatchSync] sendActiveMatches: applicationContext error: \(error)")
        }
    }

    // MARK: - Push single match update

    func sendMatchUpdate(_ match: Match, canUndo: Bool) {
        // Skip when handling a Watch command — the reply already carries the update.
        guard !isProcessingWatchCommand else { return }
        guard WCSession.default.activationState == .activated else { return }

        let state = buildWatchMatchState(from: match, canUndo: canUndo)
        guard let data = try? JSONEncoder().encode(state),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        json["type"] = "matchUpdate"

        if WCSession.default.isReachable {
            // sendMessage for immediate delivery
            WCSession.default.sendMessage(json, replyHandler: nil) { error in
                print("[WatchSync] sendMessage failed: \(error.localizedDescription)")
            }
        } else {
            // transferUserInfo queues reliably when not reachable
            WCSession.default.transferUserInfo(json)
        }

        // Also update application context so the match list stays in sync
        if let context = modelContext {
            let descriptor = FetchDescriptor<Match>()
            if let allMatches = try? context.fetch(descriptor) {
                sendActiveMatches(allMatches)
            }
        }
    }

    // MARK: - Build transfer state from a Match model

    private func buildWatchMatchState(from match: Match, canUndo: Bool = false) -> WatchMatchState {
        let sets = match.sets.sorted(by: { $0.setNumber < $1.setNumber }).map { set in
            WatchSetState(
                gamesPlayer1: set.gamesPlayer1,
                gamesPlayer2: set.gamesPlayer2,
                tiebreakScorePlayer1: set.tiebreakScorePlayer1,
                tiebreakScorePlayer2: set.tiebreakScorePlayer2,
                isComplete: set.isComplete(format: match.format)
            )
        }

        var gameScore: WatchGameScore? = nil
        // Use games.last for server info — currentGame uses isComplete which
        // checks points, and in games-only mode no points are ever played,
        // so currentGame would always return the first game.
        if let game = match.currentSet?.currentGame ?? match.currentSet?.latestGame {
            gameScore = WatchGameScore(
                player1Score: game.scoreString(forPlayer1: true, scoringStyle: match.scoringStyle),
                player2Score: game.scoreString(forPlayer1: false, scoringStyle: match.scoringStyle),
                serverIsPlayer1: game.serverIsPlayer1
            )
        }

        let isInTiebreak: Bool
        if let currentSet = match.currentSet {
            isInTiebreak = currentSet.isTiebreak(format: match.format)
        } else {
            isInTiebreak = false
        }

        return WatchMatchState(
            id: match.id.uuidString,
            player1Name: match.players.first?.name ?? "Player 1",
            player2Name: match.players.last?.name ?? "Player 2",
            scoringMode: match.scoringMode.rawValue,
            format: match.format.rawValue,
            sets: sets,
            currentGameScore: gameScore,
            isInTiebreak: isInTiebreak,
            isComplete: match.isComplete,
            canUndo: canUndo
        )
    }

    // MARK: - Process Watch commands

    private func handleWatchCommand(_ message: [String: Any],
                                    replyHandler: @escaping ([String: Any]) -> Void) {
        guard let typeStr = message["type"] as? String,
              let matchIdStr = message["matchId"] as? String,
              let uuid = UUID(uuidString: matchIdStr),
              let context = modelContext else {
            replyHandler(["error": "Invalid message"])
            return
        }

        let descriptor = FetchDescriptor<Match>(
            predicate: #Predicate<Match> { $0.id == uuid }
        )
        guard let match = try? context.fetch(descriptor).first else {
            replyHandler(["error": "Match not found"])
            return
        }

        let vm = getOrCreateViewModel(for: match, context: context)

        isProcessingWatchCommand = true
        switch typeStr {
        case "selectMatch":
            break // just return current state
        case "awardPoint":
            if let toPlayer1 = message["toPlayer1"] as? Bool {
                vm.awardPoint(toPlayer1: toPlayer1)
            }
        case "awardGame":
            if let toPlayer1 = message["toPlayer1"] as? Bool {
                vm.awardGame(toPlayer1: toPlayer1)
            }
        case "undo":
            vm.undoLastPoint()
        default:
            break
        }
        isProcessingWatchCommand = false

        let state = buildWatchMatchState(from: match, canUndo: vm.canUndo)
        if let data = try? JSONEncoder().encode(state),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json["type"] = "matchUpdate"
            replyHandler(json)
        } else {
            replyHandler(["error": "Encoding failed"])
        }

        // Clean up completed matches
        if match.isComplete {
            activeViewModels.removeValue(forKey: matchIdStr)
        }
    }

    private func getOrCreateViewModel(for match: Match, context: ModelContext) -> MatchViewModel {
        let key = match.id.uuidString
        if let existing = activeViewModels[key] {
            existing.currentMatch = match
            return existing
        }
        let vm = MatchViewModel()
        vm.configure(context: context)
        vm.currentMatch = match
        activeViewModels[key] = vm
        return vm
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("[WatchSync] activationDidComplete: state=\(activationState.rawValue), reachable=\(session.isReachable), paired=\(session.isPaired), installed=\(session.isWatchAppInstalled), error=\(String(describing: error))")
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.handleWatchCommand(message, replyHandler: replyHandler)
        }
    }
}
