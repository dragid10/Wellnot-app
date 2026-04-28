import WidgetKit
import SwiftUI

// MARK: - Constants

private let appGroupId = "group.dev.alexo.Wellnot"
private let todayEntriesKey = "widget_today_entries"
private let todayDateKey = "widget_today_date"

private let tealPrimary = Color(red: 0, green: 0x96/255.0, blue: 0x88/255.0)
private let subtleGray = Color(red: 0x9E/255.0, green: 0x9E/255.0, blue: 0x9E/255.0)

private let widgetPadding: CGFloat = 12
private let headerBottomSpacing: CGFloat = 8
private let entryVerticalSpacing: CGFloat = 4
private let entryVerticalSpacingLarge: CGFloat = 8
private let entryHorizontalSpacing: CGFloat = 8
private let addButtonSize: CGFloat = 28
private let headerFontSize: CGFloat = 14
private let timeFontSize: CGFloat = 13
private let contentFontSize: CGFloat = 14
private let addButtonFontSize: CGFloat = 18
private let moodFontSize: CGFloat = 16

// MARK: - Data Model

struct EntryData: Identifiable {
    let id: Int
    let time: String
    let mood: String
    let symptoms: String
}

// MARK: - Timeline Provider

struct TodayMoodsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayMoodsEntry {
        TodayMoodsEntry(date: Date(), entries: [
            EntryData(id: 0, time: "9:30 AM", mood: "😊", symptoms: "Headache, Fatigue"),
            EntryData(id: 1, time: "2:15 PM", mood: "😐", symptoms: "Nausea"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayMoodsEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayMoodsEntry>) -> Void) {
        let entry = loadEntry()
        // Schedule refresh at midnight so stale data from yesterday is cleared.
        let startOfTomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        completion(timeline)
    }

    private func loadEntry() -> TodayMoodsEntry {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = userDefaults.string(forKey: todayEntriesKey),
              let jsonData = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        else {
            return TodayMoodsEntry(date: Date(), entries: [])
        }

        // Check if stored data is from today — return empty if stale.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        let storedDate = userDefaults.string(forKey: todayDateKey)
        if storedDate != todayString {
            return TodayMoodsEntry(date: Date(), entries: [])
        }

        let entries = array.compactMap { dict -> EntryData? in
            guard let id = dict["id"] as? Int,
                  let time = dict["time"] as? String,
                  let mood = dict["mood"] as? String,
                  let symptoms = dict["symptoms"] as? String
            else { return nil }
            return EntryData(id: id, time: time, mood: mood, symptoms: symptoms)
        }

        return TodayMoodsEntry(date: Date(), entries: entries)
    }
}

// MARK: - Timeline Entry

struct TodayMoodsEntry: TimelineEntry {
    let date: Date
    let entries: [EntryData]
}

// MARK: - Widget View

struct TodayMoodsWidgetView: View {
    var entry: TodayMoodsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: headerBottomSpacing) {
            // Header: "Today" + "+" button
            HStack {
                Text("Today")
                    .font(.system(size: headerFontSize, weight: .bold))
                    .foregroundColor(tealPrimary)
                Spacer()
                // The homeWidget query param is required for the home_widget
                // Flutter plugin to recognize the URL on iOS.
                Link(destination: URL(string: "wellnot://newentry?homeWidget=true")!) {
                    ZStack {
                        Circle()
                            .fill(tealPrimary)
                            .frame(width: addButtonSize, height: addButtonSize)
                        Text("+")
                            .font(.system(size: addButtonFontSize, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            if entry.entries.isEmpty {
                Text("No entries logged today")
                    .font(.system(size: contentFontSize))
                    .foregroundColor(subtleGray)
            } else if family == .systemSmall {
                // Compact layout: time + mood emoji only
                VStack(alignment: .leading, spacing: entryVerticalSpacing) {
                    ForEach(entry.entries.prefix(maxEntries)) { item in
                        Link(destination: URL(string: "wellnot://entry/\(item.id)?homeWidget=true")!) {
                            HStack(spacing: entryHorizontalSpacing) {
                                Text(item.time)
                                    .font(.system(size: timeFontSize))
                                    .foregroundColor(.primary)
                                Text(item.mood)
                                    .font(.system(size: moodFontSize))
                            }
                        }
                    }
                }
            } else {
                // Medium/Large layout: time + mood + symptoms
                VStack(alignment: .leading, spacing: family == .systemLarge ? entryVerticalSpacingLarge : entryVerticalSpacing) {
                    ForEach(entry.entries.prefix(maxEntries)) { item in
                        Link(destination: URL(string: "wellnot://entry/\(item.id)?homeWidget=true")!) {
                            HStack(spacing: entryHorizontalSpacing) {
                                Text(item.time)
                                    .font(.system(size: timeFontSize))
                                    .foregroundColor(.primary)
                                Text(item.symptoms.isEmpty ? item.mood : "\(item.mood) - \(item.symptoms)")
                                    .font(.system(size: contentFontSize))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(widgetPadding)
    }

    /// Max visible entries based on widget size.
    private var maxEntries: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        case .systemLarge: return 10
        default: return 4
        }
    }
}

// MARK: - Widget Definition

struct TodayMoodsWidget: Widget {
    let kind: String = "TodayMoodsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayMoodsProvider()) { entry in
            if #available(iOS 17.0, *) {
                TodayMoodsWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TodayMoodsWidgetView(entry: entry)
                    .background()
            }
        }
        .configurationDisplayName("Today's Moods")
        .description("See your logged moods for today")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct WellnotWidgets: WidgetBundle {
    var body: some Widget {
        TodayMoodsWidget()
    }
}

// MARK: - Preview

#if DEBUG
struct TodayMoodsWidget_Previews: PreviewProvider {
    static let sampleEntries = [
        EntryData(id: 1, time: "9:30 AM", mood: "😊", symptoms: "Headache, Fatigue"),
        EntryData(id: 2, time: "2:15 PM", mood: "😐", symptoms: "Nausea"),
        EntryData(id: 3, time: "5:00 PM", mood: "😢", symptoms: "Back Pain"),
    ]

    static var previews: some View {
        TodayMoodsWidgetView(entry: TodayMoodsEntry(date: Date(), entries: sampleEntries))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")
        TodayMoodsWidgetView(entry: TodayMoodsEntry(date: Date(), entries: sampleEntries))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")
        TodayMoodsWidgetView(entry: TodayMoodsEntry(date: Date(), entries: sampleEntries))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
    }
}
#endif
