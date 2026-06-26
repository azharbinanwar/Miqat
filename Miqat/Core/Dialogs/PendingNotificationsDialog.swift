import SwiftUI
import UserNotifications

struct PendingNotificationItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let trigger: String
}

struct PendingNotificationsDialog: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationViewModel.self) private var vm
    @State private var items:        [PendingNotificationItem] = []
    @State private var rawRequests:  [UNNotificationRequest]   = []
    @State private var loading       = true
    @State private var query         = ""
    @State private var summaryCopied = false

    private var filtered: [PendingNotificationItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        let q = query.lowercased()
        return items.filter {
            $0.title.lowercased().contains(q) ||
            $0.body.lowercased().contains(q)  ||
            $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scheduled Notifications")
                        .font(.system(size: 16, weight: .bold))
                    if !loading {
                        Text(query.isEmpty ? "\(items.count) pending" : "\(filtered.count) of \(items.count)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    // Refresh — always fetches live count from system
                    Button {
                        Task { await loadPending() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh pending list from system")

                    // Summary — always fetches fresh before printing
                    Button {
                        Task {
                            let fresh = await UNUserNotificationCenter.current().pendingNotificationRequests()
                            let log = NotificationCounter.summary(vm: vm, pending: fresh)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(log, forType: .string)
                            withAnimation { summaryCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { summaryCopied = false }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: summaryCopied ? "checkmark.circle.fill" : "doc.on.clipboard")
                                .font(.system(size: 11, weight: .semibold))
                            Text(summaryCopied ? "Copied!" : "Summary")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(summaryCopied ? AppColor.accentTeal : Color.secondary, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                TextField("Search — Fajr, Mulk, Kahf...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider()

            if loading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                Image(systemName: query.isEmpty ? "bell.slash" : "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
                Text(query.isEmpty ? "No notifications scheduled" : "No results for \"\(query)\"")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filtered) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColor.accentTeal)
                                    .frame(width: 32, height: 32)
                                    .background(AppColor.accentTeal.opacity(0.1),
                                                in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(item.body)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(item.trigger)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(AppColor.accentTeal.opacity(0.8))
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)

                            if item.id != filtered.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .task { await loadPending() }
    }

    private func loadPending() async {
        loading = true
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let sorted = requests.sorted {
            triggerDate($0) ?? .distantFuture < triggerDate($1) ?? .distantFuture
        }
        rawRequests = sorted
        items = sorted.map { req in
            PendingNotificationItem(
                id: req.identifier,
                title: req.content.title,
                body: req.content.body,
                trigger: triggerLabel(req)
            )
        }
        loading = false
    }

    private func triggerDate(_ req: UNNotificationRequest) -> Date? {
        if let cal = req.trigger as? UNCalendarNotificationTrigger {
            return Calendar.current.date(from: cal.dateComponents)
        }
        if let interval = req.trigger as? UNTimeIntervalNotificationTrigger {
            return interval.nextTriggerDate()
        }
        return nil
    }

    private func triggerLabel(_ req: UNNotificationRequest) -> String {
        if let date = triggerDate(req) {
            let f = DateFormatter()
            f.dateFormat = "EEE dd MMM · HH:mm"
            return f.string(from: date)
        }
        return req.identifier
    }
}
