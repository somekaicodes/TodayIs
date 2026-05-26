//
//  FirestoreService.swift
//  TodayIs
//
//  Reads and writes GoalCalendar + StreakRecord data to Firestore.
//
//  Firestore structure:
//    users/{userID}/
//      calendars/{calendarID}   { id, title, startDate }
//        streaks/{recordID}     { id, years, months, days, savedDate }
//
//  Sync strategy:
//    • On sign-in:  if Firestore has data → download into SwiftData (cloud wins)
//                  else → upload all local SwiftData to Firestore
//    • On any calendar change: upload to Firestore when signed in
//    • On sign-out: local SwiftData is left untouched
//

import Foundation
import FirebaseFirestore

@Observable
final class FirestoreService {
    var isSyncing = false

    private let db = Firestore.firestore()

    // MARK: - Collection paths

    private func calendarsRef(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("calendars")
    }

    private func streaksRef(userID: String, calendarID: String) -> CollectionReference {
        calendarsRef(userID: userID).document(calendarID).collection("streaks")
    }

    // MARK: - Check for existing cloud data

    /// Returns true if the user already has at least one calendar saved in Firestore.
    func hasCloudData(userID: String) async -> Bool {
        let snapshot = try? await calendarsRef(userID: userID).limit(to: 1).getDocuments()
        return !(snapshot?.documents.isEmpty ?? true)
    }

    // MARK: - Upload all calendars (local → Firestore)

    func uploadAll(calendars: [GoalCalendar], userID: String) async {
        guard !calendars.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Calendars in a batch
        let batch = db.batch()
        for calendar in calendars {
            let ref = calendarsRef(userID: userID).document(calendar.id.uuidString)
            batch.setData(calendarData(calendar), forDocument: ref)
        }
        do { try await batch.commit() } catch {
            print("[Firestore] Batch upload error: \(error)")
            return
        }

        // Streak sub-collections (can't go in a cross-collection batch easily)
        for calendar in calendars {
            await uploadStreaks(calendar.streakHistory,
                                calendarID: calendar.id.uuidString,
                                userID: userID)
        }
    }

    // MARK: - Upload one calendar (called after each local change)

    func syncCalendar(_ calendar: GoalCalendar, userID: String) async {
        let ref = calendarsRef(userID: userID).document(calendar.id.uuidString)
        try? await ref.setData(calendarData(calendar))
        await uploadStreaks(calendar.streakHistory,
                            calendarID: calendar.id.uuidString,
                            userID: userID)
    }

    // MARK: - Delete a calendar from Firestore

    func deleteCalendar(id: UUID, userID: String) async {
        let calID = id.uuidString
        // Delete streak sub-documents first
        if let docs = try? await streaksRef(userID: userID, calendarID: calID).getDocuments() {
            for doc in docs.documents {
                try? await doc.reference.delete()
            }
        }
        try? await calendarsRef(userID: userID).document(calID).delete()
    }

    // MARK: - Download all calendars (Firestore → local)

    /// Returns (GoalCalendar, [StreakRecord]) pairs ready to be inserted into SwiftData,
    /// or nil if the download fails.
    func downloadAll(userID: String) async -> [(GoalCalendar, [StreakRecord])]? {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let snapshot = try await calendarsRef(userID: userID).getDocuments()
            var results: [(GoalCalendar, [StreakRecord])] = []

            for doc in snapshot.documents {
                let data = doc.data()
                guard
                    let idStr       = data["id"] as? String,
                    let id          = UUID(uuidString: idStr),
                    let title       = data["title"] as? String,
                    let startStamp  = data["startDate"] as? Timestamp
                else { continue }

                let calendar = GoalCalendar(id: id, title: title, startDate: startStamp.dateValue())
                let streaks  = await downloadStreaks(calendarID: idStr, userID: userID)
                results.append((calendar, streaks))
            }
            return results
        } catch {
            print("[Firestore] Download error: \(error)")
            return nil
        }
    }

    // MARK: - Private helpers

    private func calendarData(_ calendar: GoalCalendar) -> [String: Any] {
        [
            "id":        calendar.id.uuidString,
            "title":     calendar.title,
            "startDate": Timestamp(date: calendar.startDate)
        ]
    }

    private func uploadStreaks(_ streaks: [StreakRecord], calendarID: String, userID: String) async {
        let ref = streaksRef(userID: userID, calendarID: calendarID)
        for streak in streaks {
            let data: [String: Any] = [
                "id":        streak.id.uuidString,
                "years":     streak.years,
                "months":    streak.months,
                "days":      streak.days,
                "savedDate": Timestamp(date: streak.savedDate)
            ]
            try? await ref.document(streak.id.uuidString).setData(data)
        }
    }

    private func downloadStreaks(calendarID: String, userID: String) async -> [StreakRecord] {
        guard let snapshot = try? await streaksRef(userID: userID, calendarID: calendarID).getDocuments()
        else { return [] }

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard
                let idStr      = data["id"] as? String,
                let id         = UUID(uuidString: idStr),
                let years      = data["years"] as? Int,
                let months     = data["months"] as? Int,
                let days       = data["days"] as? Int,
                let savedStamp = data["savedDate"] as? Timestamp
            else { return nil }

            return StreakRecord(id: id, years: years, months: months, days: days,
                                savedDate: savedStamp.dateValue())
        }
    }
}
