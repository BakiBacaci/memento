import SwiftUI
import WidgetKit

// Günün sözü — ana ekran (küçük / orta) ve kilit ekranı (dikdörtgen / satır içi).
//
// Flutter tarafı (DailyService) önümüzdeki 45 günün sözlerini App Group
// içindeki UserDefaults'a "days" anahtarıyla JSON olarak yazıyor. Burada
// her gece yarısı için bir zaman çizelgesi girdisi üretiliyor; uygulama
// açılmasa da söz her gün değişiyor.

private let appGroup = "group.com.bakibacaci.memento"

struct DayQuote: Codable {
    let d: String
    let t: String
    let a: String
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let text: String
    let author: String
    let label: String
}

struct Provider: TimelineProvider {
    private let fallback = QuoteEntry(
        date: Date(),
        text: "Kendini bilmek, tüm bilgeliğin başlangıcıdır.",
        author: "Aristoteles",
        label: "GÜNÜN SÖZÜ"
    )

    private func load() -> (days: [DayQuote], label: String) {
        let defaults = UserDefaults(suiteName: appGroup)
        let label = defaults?.string(forKey: "label") ?? "GÜNÜN SÖZÜ"
        guard let raw = defaults?.string(forKey: "days"),
              let data = raw.data(using: .utf8),
              let days = try? JSONDecoder().decode([DayQuote].self, from: data)
        else { return ([], label) }
        return (days, label)
    }

    private static let ymd: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func entry(for date: Date, days: [DayQuote], label: String) -> QuoteEntry {
        let key = Self.ymd.string(from: date)
        let match = days.first { $0.d == key } ?? days.last { $0.d < key }
        guard let q = match else { return fallback }
        return QuoteEntry(date: date, text: q.t, author: q.a, label: label)
    }

    func placeholder(in context: Context) -> QuoteEntry { fallback }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let (days, label) = load()
        completion(entry(for: Date(), days: days, label: label))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let (days, label) = load()
        let cal = Calendar.current
        var entries = [entry(for: Date(), days: days, label: label)]
        var midnight = cal.startOfDay(for: Date())
        for _ in 0..<7 {
            midnight = cal.date(byAdding: .day, value: 1, to: midnight)!
            entries.append(entry(for: midnight, days: days, label: label))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
private let ink = Color(red: 0.95, green: 0.93, blue: 0.89)
private let muted = Color(red: 0.60, green: 0.57, blue: 0.51)

struct MementoWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: QuoteEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("“\(entry.text)”")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .lineLimit(3)
                Text("— \(entry.author)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.label)
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2)
                    .foregroundStyle(gold)
                Spacer(minLength: 0)
                Text("“\(entry.text)”")
                    .font(.system(size: family == .systemSmall ? 14 : 17, design: .serif))
                    .italic()
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(family == .systemSmall ? 5 : 4)
                Spacer(minLength: 0)
                Text("— \(entry.author)")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct MementoWidget: Widget {
    let kind = "MementoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MementoWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            colors: [Color(red: 0.10, green: 0.09, blue: 0.07),
                                     Color(red: 0.04, green: 0.04, blue: 0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
            } else {
                MementoWidgetView(entry: entry)
                    .padding()
                    .background(Color(red: 0.06, green: 0.06, blue: 0.06))
            }
        }
        .configurationDisplayName("Günün Sözü")
        .description("Her gün yeni bir söz — ana ekranda ve kilit ekranında.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryRectangular, .accessoryInline])
    }
}

@main
struct MementoWidgetBundle: WidgetBundle {
    var body: some Widget { MementoWidget() }
}
