//
//  ContentView.swift
//  DateAndCalenderPicker
//
//  Updated by Created by Sopnil Sohan on 15/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var calendarIdentifier: Calendar.Identifier = .gregorian
    @State private var localeIdentifier: String = Locale.current.identifier
    @State private var displayMonth: Date = Date()
    @State private var startDate: Date?
    @State private var endDate: Date?

    private let minDate: Date = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
    private let maxDate: Date = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    sectionHeader(title: "Quick pick")
                    horizontalDatePills

                    sectionHeader(title: "Month calendar")
                    calendarToolbar
                    monthGrid

                    sectionHeader(title: "Preferences")
                    preferencesPanel
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Date & Calendar Picker")
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Subviews
private extension ContentView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan with confidence")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 6) {
                labelRow(title: "Selected range", value: selectionLabel)
                labelRow(title: "Min / Max", value: "\(dateLabel(minDate)) – \(dateLabel(maxDate))")
                labelRow(title: "Locale", value: localeIdentifier)
                labelRow(title: "Calendar", value: calendarName(calendarIdentifier))
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
        .padding()
        .background(
            LinearGradient(colors: [.blue.opacity(0.12), .cyan.opacity(0.08)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .cornerRadius(18)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selection summary")
    }

    var horizontalDatePills: some View {
        let calendar = activeCalendar
        let today = calendar.startOfDay(for: Date())
        let dates = (0..<21).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dates, id: \.self) { date in
                    let disabled = !isSelectable(date)
                    Button {
                        toggleSelection(for: date)
                    } label: {
                        VStack(spacing: 6) {
                            Text(dayOfWeek(for: date))
                                .font(.caption)
                                .foregroundColor(disabled ? .secondary : .blue)
                            Text(dayNumber(for: date))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(pillBackground(for: date, disabled: disabled))
                        .overlay(
                            Capsule()
                                .strokeBorder(disabled ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(disabled)
                    .accessibilityLabel("\(accessibilityDate(date))")
                    .accessibilityHint(disabled ? "Disabled by date rules" : "Tap to include in range")
                }
            }
            .padding(.horizontal, 4)
        }
    }

    var calendarToolbar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthTitle(for: displayMonth))
                    .font(.headline)
                Text("Swipe or use arrows to change")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                .accessibilityLabel("Previous month")

                Button {
                    displayMonth = Date()
                } label: {
                    Image(systemName: "dot.circle")
                        .padding(8)
                }
                .accessibilityLabel("Jump to current month")

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
                .accessibilityLabel("Next month")
            }
            .buttonStyle(.bordered)
        }
    }

    var monthGrid: some View {
        let calendar = activeCalendar
        let days = monthDays(for: displayMonth)

        return VStack(spacing: 12) {
            HStack {
                ForEach(weekdaySymbols(), id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { day in
                    if let date = day {
                        let disabled = !isSelectable(date)
                        Button {
                            toggleSelection(for: date)
                        } label: {
                            VStack(spacing: 4) {
                                Text(dayNumber(for: date))
                                    .font(.body.weight(.medium))
                                Text(shortMonth(for: date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(dayBackground(for: date, disabled: disabled))
                        }
                        .disabled(disabled)
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(accessibilityDate(date))")
                        .accessibilityHint(disabled ? "Outside allowed dates" : "Tap to add to range")
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }

    var preferencesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Locale", selection: $localeIdentifier) {
                Text("System (\(Locale.current.identifier))").tag(Locale.current.identifier)
                Text("English (US)").tag("en_US")
                Text("French (FR)").tag("fr_FR")
                Text("Arabic (SA)").tag("ar_SA")
            }
            .pickerStyle(.segmented)

            Picker("Calendar", selection: $calendarIdentifier) {
                Text("Gregorian").tag(Calendar.Identifier.gregorian)
                Text("ISO 8601").tag(Calendar.Identifier.iso8601)
                Text("Buddhist").tag(Calendar.Identifier.buddhist)
                Text("Islamic").tag(Calendar.Identifier.islamicUmmAlQura)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Helpers
private extension ContentView {
    var activeCalendar: Calendar {
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.locale = Locale(identifier: localeIdentifier)
        calendar.firstWeekday = 2 // Monday-first for consistency
        return calendar
    }

    var selectionLabel: String {
        switch (startDate, endDate) {
        case (.some(let start), .some(let end)):
            return "\(dateLabel(start)) → \(dateLabel(end))"
        case (.some(let start), .none):
            return "\(dateLabel(start)) (tap end date)"
        default:
            return "No dates selected"
        }
    }

    func labelRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .padding(.top, 4)
    }

    func calendarName(_ identifier: Calendar.Identifier) -> String {
        switch identifier {
        case .gregorian: return "Gregorian"
        case .iso8601: return "ISO 8601"
        case .buddhist: return "Buddhist"
        case .islamicUmmAlQura: return "Islamic (Umm al-Qura)"
        default: return String(describing: identifier).capitalized
        }
    }

    func moveMonth(by value: Int) {
        if let newMonth = activeCalendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newMonth
        }
    }

    func monthDays(for date: Date) -> [Date?] {
        let calendar = activeCalendar
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
            let daysCount = calendar.range(of: .day, in: .month, for: date)?.count
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: (firstWeekday - calendar.firstWeekday + 7) % 7)
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(date)
            }
        }
        return days
    }

    func toggleSelection(for date: Date) {
        guard isSelectable(date) else { return }
        let day = startOfDay(date)

        if startDate == nil {
            startDate = day
            endDate = nil
        } else if let start = startDate, endDate == nil {
            if day < start {
                startDate = day
            } else {
                endDate = day
            }
        } else {
            startDate = day
            endDate = nil
        }
    }

    func isSelectable(_ date: Date) -> Bool {
        let day = startOfDay(date)
        return day >= startOfDay(minDate) && day <= startOfDay(maxDate)
    }

    func isInRange(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        let day = startOfDay(date)
        if let end = endDate {
            return day >= start && day <= end
        }
        return day == start
    }

    func pillBackground(for date: Date, disabled: Bool) -> some View {
        let selected = isInRange(date)
        return Capsule()
            .fill(selected ? Color.blue.opacity(0.18) : Color(.systemBackground))
            .overlay(
                Capsule()
                    .stroke(selected ? Color.blue : .clear, lineWidth: 1.2)
            )
            .opacity(disabled ? 0.6 : 1)
    }

    func dayBackground(for date: Date, disabled: Bool) -> some View {
        let selected = isInRange(date)
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(selected ? Color.blue.opacity(0.2) : Color(.systemBackground))
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.blue : Color.clear, lineWidth: 1.2)
        }
        .opacity(disabled ? 0.4 : 1)
    }

    func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = activeCalendar
        formatter.locale = activeCalendar.locale
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func dayNumber(for date: Date) -> String {
        String(activeCalendar.component(.day, from: date))
    }

    func weekdaySymbols() -> [String] {
        let symbols = activeCalendar.veryShortWeekdaySymbols
        let start = activeCalendar.firstWeekday - 1
        var ordered: [String] = []
        ordered.append(contentsOf: symbols[start...])
        ordered.append(contentsOf: symbols[..<start])
        return ordered
    }

    func shortMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = activeCalendar
        formatter.locale = activeCalendar.locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = activeCalendar
        formatter.locale = activeCalendar.locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = activeCalendar
        formatter.locale = activeCalendar.locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    func accessibilityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = activeCalendar
        formatter.locale = activeCalendar.locale
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    func startOfDay(_ date: Date) -> Date {
        activeCalendar.startOfDay(for: date)
    }
}

