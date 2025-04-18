//
//  NotificationView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/8/25.
//

import SwiftUI

enum ViewMode {
    case single, multiple
}

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var viewMode: ViewMode = .single
    @State private var showCalendar = false
    @State private var selectedFilter = "Recent"
    let filters = ["Recent", "Most Active", "Most View"]
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                      
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your\nNotifications")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Stay updated with your events")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick Action Button
                        NavigationLink(destination: CreateView()) {
                            HStack {
                                Text("Create New Event")
                                    .foregroundColor(.blue)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filters, id: \.self) { filter in
                                FilterTab(title: filter, isSelected: filter == selectedFilter) {
                                    withAnimation {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Text("Join Community and RSVP")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Event Cards
                    LazyVStack(spacing: 16) {
                        ForEach(eventsForSelectedDate()) { event in
                            EventNotificationCard(event: event)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.dynamic)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCalendar.toggle() }) {
                        Image(systemName: "calendar")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(selectedDate: $selectedDate, currentMonth: $currentMonth, viewMode: $viewMode)
            }
        }
    }
    
    private func eventsForSelectedDate() -> [Event] {
        eventsForDate(selectedDate)
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        return sampleEvents.filter { event in
            let eventDate = event.startDate
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }
}

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color.clear)
                .cornerRadius(20)
        }
    }
}

struct EventNotificationCard: View {
    let event: Event
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var hasTicket = false
    
    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: event)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(event.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(Int.random(in: 1000...50000)) Views")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = event.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.vertical, 4)
                }
                
                HStack {
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(Color.randomize)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(event.participants[safe: i]?.prefix(1) ?? ""))
                                    .foregroundColor(.white)
                            )
                            .offset(x: CGFloat(i * -10))
                    }
                    Text("+\(max(0, event.participants.count - 4))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, -8)
                    
                    Spacer()
                    
                    Button(action: {
                        if let userId = firebaseManager.currentUser?.uid {
                            hasTicket = event.participants.contains(userId)
                        }
                    }) {
                        Text(hasTicket ? "Joined" : "Join Event")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(hasTicket ? Color.green : Color.blue)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .onAppear {
            if let userId = firebaseManager.currentUser?.uid {
                hasTicket = event.participants.contains(userId)
            }
        }
    }
}

struct CalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    @Binding var viewMode: ViewMode
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }
    
    private func eventsForSelectedDate() -> [Event] {
        eventsForDate(selectedDate)
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        return sampleEvents.filter { event in
            let eventDate = event.startDate
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }
    
    private func hasEvents(for date: Date) -> Bool {
        !eventsForDate(date).isEmpty
    }
    
    private func moveMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Month and View Mode Selector
                    HStack {
                        HStack(spacing: 16) {
                            Button(action: { moveMonth(by: -1) }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(currentMonth.formatted(.dateTime.month().year()))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button(action: { moveMonth(by: 1) }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Button(action: { viewMode = .single }) {
                                Text("Single")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewMode == .single ? Color.purple : Color.clear)
                                    .foregroundColor(viewMode == .single ? .white : .gray)
                            }
                            
                            Button(action: { viewMode = .multiple }) {
                                Text("Multiple")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewMode == .multiple ? Color.blue : Color.clear)
                                    .foregroundColor(viewMode == .multiple ? .white : .gray)
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding()
                    
                    // Month Calendar
                    VStack(spacing: 16) {
                        // Weekday headers
                        HStack(spacing: 15) {
                            ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                                    Text(day)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                }
                        }
                        .padding(.horizontal)
                        
                        // Calendar grid
                        VStack(spacing: 8) {
                            ForEach(monthDates, id: \.self) { week in
                                HStack(spacing: 0) {
                                    ForEach(week.indices, id: \.self) { index in
                                        if let date = week[index] {
                                            MonthDayButton(
                                                date: date,
                                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                                hasEvents: hasEvents(for: date)
                                            ) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedDate = date
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(5)
                    .padding(.vertical,10)
                    .background(Color.gray.opacity(0.10))
                    .cornerRadius(18)
                    .padding()
                    
                    // Events List for Selected Date
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Let's view an event!")
                                        .font(.title3)
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, .blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    Spacer()
                                   
                                        Image(systemName: "text.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.7))
                                }
                                Text("Events happening today")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        ForEach(Array(eventsForSelectedDate().enumerated()), id: \.element.id) { index, event in
                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                EventRow(event: event, isLastEvent: index == eventsForSelectedDate().count - 1)
                                    .padding(.top, index == 0 ? 16 : 0)
                            }
                        }
                        
                        if eventsForSelectedDate().isEmpty {
                            NoEventsView()
                                .transition(.opacity)
                        }
                    }
                    .fontWeight(.bold)
                        .padding(.horizontal)
                }
                .animation(.easeInOut, value: selectedDate)
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var monthDates: [[Date?]] {
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let offsetDays = firstWeekday - calendar.firstWeekday
        
        let firstDate = calendar.date(byAdding: .day, value: -offsetDays, to: monthInterval.start)!
        
        var weeks: [[Date?]] = []
        var week: [Date?] = []
        var currentDate = firstDate
        
        // Previous month dates
        for _ in 0..<offsetDays {
            week.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Current month dates
        while currentDate < monthInterval.end {
            if week.count == 7 {
                weeks.append(week)
                week = []
            }
            week.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Next month dates
        while week.count < 7 {
            week.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        weeks.append(week)
        
        // Add remaining weeks to make it 6 rows
        while weeks.count < 6 {
            var nextWeek: [Date?] = []
            for _ in 0..<7 {
                nextWeek.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            weeks.append(nextWeek)
        }
        
        return weeks
    }
}

struct MonthDayButton: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasEvents: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : 
                                   isCurrentMonth ? .primary : .gray.opacity(0.5))
                
                // Event indicator
                Circle()
                    .fill(hasEvents ? (isSelected ? .white : .blue) : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 36, height: 36)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct Previews_NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
            .environmentObject(FirebaseManager.shared)
    }
}

// For testing purposes
struct EventNotificationCard_Previews: PreviewProvider {
    static var previews: some View {
        EventNotificationCard(event: sampleEvent)
            .environmentObject(FirebaseManager.shared)
            .padding()
    }
}

struct EventRow: View {
    let event: Event
    let isLastEvent: Bool
    
    private func timeUntilEvent() -> String {
        let eventDate = event.startDate
        let timeUntilEvent = eventDate.timeIntervalSinceNow
        
        if timeUntilEvent < 0 {
            let difference = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: eventDate)
            if let hours = difference.hour {
                if hours < 24 {
                    if hours == 0 {
                        return "In less than an hour"
                    }
                    return "In \(hours) hour\(hours == 1 ? "" : "s")"
                }
            }
            return eventDate.formatted(date: .abbreviated, time: .shortened)
        }
        return ""
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    if let startDate = event.startDate {
                        Text(startDate.formatted(.dateTime.hour().minute()))
                            .foregroundColor(.gray)
                        +
                        Text(", Today")
                            .foregroundColor(.gray)
                    }
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            Text(timeUntilEvent())
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.10))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical, 4)
    }
}

struct NoEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                )
            
            VStack(spacing: 8) {
                Text("No events yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Your scheduled events will appear here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
