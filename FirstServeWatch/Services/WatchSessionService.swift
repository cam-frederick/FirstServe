//
//  WatchSessionService.swift
//  FirstServe Watch
//
//  Manages WatchConnectivity session on the watchOS side.
//  Receives match data from the iPhone and sends scoring commands.
//

import Foundation
import WatchConnectivity
import os

private let logger = Logger(subsystem: "com.Cam.FirstServe.watchkitapp", category: "WatchSession")

@Observable
final class WatchSessionService: NSObject {
    var activeMatches: [WatchMatchState] = []
    var selectedMatch: WatchMatchState?
    var isPhoneReachable = false
    /// True while waiting for the phone to confirm an optimistic update.
    var pendingConfirmation = false

    /// History of pre-optimistic states for instant undo on Watch.
    private var optimisticHistory: [WatchMatchState] = []
    /// The confirmed state before the most recent phone update, used for undo after confirmation.
    private var previousConfirmedMatch: WatchMatchState?

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            logger.warning("WCSession not supported")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        logger.info("WCSession activating...")
    }

    // MARK: - Commands → iPhone

    func selectMatch(_ matchId: String) {
        sendCommand(["type": "selectMatch", "matchId": matchId])
    }

    func awardPoint(matchId: String, toPlayer1: Bool) {
        let previous = selectedMatch
        if let current = selectedMatch, current.id == matchId {
            optimisticHistory.append(current)
            selectedMatch = optimisticPoint(current, toPlayer1: toPlayer1)
        }
        pendingConfirmation = true
        // Defer network work so SwiftUI can re-render with the optimistic state first
        DispatchQueue.main.async { [self] in
            sendCommand(["type": "awardPoint", "matchId": matchId, "toPlayer1": toPlayer1],
                         rollback: previous)
        }
    }

    func awardGame(matchId: String, toPlayer1: Bool) {
        let previous = selectedMatch
        if let current = selectedMatch, current.id == matchId {
            optimisticHistory.append(current)
            selectedMatch = optimisticGame(current, toPlayer1: toPlayer1)
        }
        pendingConfirmation = true
        DispatchQueue.main.async { [self] in
            sendCommand(["type": "awardGame", "matchId": matchId, "toPlayer1": toPlayer1],
                         rollback: previous)
        }
    }

    func undo(matchId: String) {
        // Pop the last pre-optimistic state for instant visual undo
        if let previous = optimisticHistory.popLast(), previous.id == matchId {
            selectedMatch = previous
        } else if let previous = previousConfirmedMatch, previous.id == matchId {
            // Phone already confirmed — revert to the state before that confirmation
            selectedMatch = previous
            previousConfirmedMatch = nil
        } else if var current = selectedMatch, current.id == matchId {
            current.canUndo = false
            selectedMatch = current
        }
        pendingConfirmation = true
        DispatchQueue.main.async { [self] in
            sendCommand(["type": "undo", "matchId": matchId])
        }
    }

    private func sendCommand(_ message: [String: Any], rollback: WatchMatchState? = nil) {
        guard WCSession.default.isReachable else {
            logger.warning("Phone not reachable, command dropped")
            // Roll back optimistic update
            if let rollback { selectedMatch = rollback }
            pendingConfirmation = false
            return
        }
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleMatchUpdate(reply)
            }
        }, errorHandler: { [weak self] error in
            logger.error("sendMessage error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                if let rollback { self?.selectedMatch = rollback }
                self?.pendingConfirmation = false
            }
        })
    }

    // MARK: - Optimistic Predictions

    /// Predict the next state after awarding a point (standard scoring or tiebreak).
    private func optimisticPoint(_ state: WatchMatchState, toPlayer1: Bool) -> WatchMatchState {
        var m = state

        // Tiebreak: increment numeric score
        if m.isInTiebreak, m.sets.count > 0 {
            let i = m.sets.count - 1
            if toPlayer1 {
                m.sets[i].tiebreakScorePlayer1 = (m.sets[i].tiebreakScorePlayer1 ?? 0) + 1
            } else {
                m.sets[i].tiebreakScorePlayer2 = (m.sets[i].tiebreakScorePlayer2 ?? 0) + 1
            }
            m.canUndo = true
            return m
        }

        // Regular game: advance point score
        guard var gs = m.currentGameScore else { return m }

        let myScore = toPlayer1 ? gs.player1Score : gs.player2Score
        let theirScore = toPlayer1 ? gs.player2Score : gs.player1Score

        var gameWon = false

        switch myScore {
        case "0":
            if toPlayer1 { gs.player1Score = "15" } else { gs.player2Score = "15" }
        case "15":
            if toPlayer1 { gs.player1Score = "30" } else { gs.player2Score = "30" }
        case "30":
            if toPlayer1 { gs.player1Score = "40" } else { gs.player2Score = "40" }
        case "40":
            switch theirScore {
            case "40":
                // Deuce → Ad
                if toPlayer1 { gs.player1Score = "AD" } else { gs.player2Score = "AD" }
            case "AD":
                // Back to deuce
                gs.player1Score = "40"
                gs.player2Score = "40"
            default:
                gameWon = true
            }
        case "AD":
            gameWon = true
        default:
            break // unknown score string, leave unchanged
        }

        if gameWon {
            // Award game to set, reset game score, toggle server
            if m.sets.count > 0 {
                let i = m.sets.count - 1
                if toPlayer1 {
                    m.sets[i].gamesPlayer1 += 1
                } else {
                    m.sets[i].gamesPlayer2 += 1
                }
                // Check if entering tiebreak (6-6)
                if m.sets[i].gamesPlayer1 == 6 && m.sets[i].gamesPlayer2 == 6 {
                    m.isInTiebreak = true
                    m.sets[i].tiebreakScorePlayer1 = 0
                    m.sets[i].tiebreakScorePlayer2 = 0
                }
            }
            gs.player1Score = "0"
            gs.player2Score = "0"
            gs.serverIsPlayer1 = !gs.serverIsPlayer1
        }

        m.currentGameScore = gs
        m.canUndo = true
        return m
    }

    /// Predict the next state after awarding a game (games-only mode).
    private func optimisticGame(_ state: WatchMatchState, toPlayer1: Bool) -> WatchMatchState {
        var m = state
        guard m.sets.count > 0 else { return m }

        let i = m.sets.count - 1
        if toPlayer1 {
            m.sets[i].gamesPlayer1 += 1
        } else {
            m.sets[i].gamesPlayer2 += 1
        }

        // Toggle server
        if var gs = m.currentGameScore {
            gs.serverIsPlayer1 = !gs.serverIsPlayer1
            m.currentGameScore = gs
        }

        m.canUndo = true
        return m
    }

    // MARK: - Parse helpers

    private func handleApplicationContext(_ context: [String: Any]) {
        logger.info("handleApplicationContext: keys=\(context.keys.joined(separator: ","))")

        guard context["type"] as? String == "activeMatches" else {
            logger.warning("handleApplicationContext: type is not activeMatches, got \(context["type"] as? String ?? "nil")")
            return
        }
        guard let matchesObj = context["matches"] else {
            logger.warning("handleApplicationContext: no 'matches' key")
            return
        }

        guard let data = try? JSONSerialization.data(withJSONObject: matchesObj) else {
            logger.error("handleApplicationContext: JSONSerialization failed")
            return
        }

        do {
            let matches = try JSONDecoder().decode([WatchMatchState].self, from: data)
            activeMatches = matches.filter { !$0.isComplete }
            logger.info("handleApplicationContext: decoded \(matches.count) matches, \(self.activeMatches.count) active")
        } catch {
            logger.error("handleApplicationContext: decode error: \(error)")
            return
        }

        // Also refresh selectedMatch if it's in the updated list
        if let selected = selectedMatch,
           let updated = activeMatches.first(where: { $0.id == selected.id }) {
            selectedMatch = updated
        }
    }

    private func handleMatchUpdate(_ message: [String: Any]) {
        // Strip the "type" key before decoding
        var payload = message
        payload.removeValue(forKey: "type")

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let state = try? JSONDecoder().decode(WatchMatchState.self, from: data) else { return }

        // Save current confirmed state so undo can revert to it
        previousConfirmedMatch = selectedMatch
        selectedMatch = state
        // Phone reply is authoritative — clear optimistic state
        optimisticHistory.removeAll()
        pendingConfirmation = false

        // Update in the active list
        if let idx = activeMatches.firstIndex(where: { $0.id == state.id }) {
            if state.isComplete {
                activeMatches.remove(at: idx)
            } else {
                activeMatches[idx] = state
            }
        }
    }

    private func handleMatchCompleted(_ message: [String: Any]) {
        guard let matchId = message["matchId"] as? String else { return }
        activeMatches.removeAll { $0.id == matchId }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        logger.info("activationDidComplete: state=\(activationState.rawValue), reachable=\(session.isReachable), error=\(String(describing: error))")
        logger.info("receivedApplicationContext keys: \(session.receivedApplicationContext.keys.joined(separator: ","))")
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            self.handleApplicationContext(session.receivedApplicationContext)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            // Re-check application context when reachability changes
            if session.isReachable {
                self.handleApplicationContext(session.receivedApplicationContext)
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.handleApplicationContext(applicationContext)
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            let type = message["type"] as? String
            if type == "matchUpdate" {
                self.handleMatchUpdate(message)
            } else if type == "matchCompleted" {
                self.handleMatchCompleted(message)
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            let type = userInfo["type"] as? String
            if type == "matchUpdate" {
                self.handleMatchUpdate(userInfo)
            }
        }
    }
}
