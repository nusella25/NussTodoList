import SwiftUI
import UserNotifications

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var durationMinutes: Int
    var isCompleted: Bool = false
    var dateString: String
}

struct ContentView: View {
    @AppStorage("appTitle") private var appTitle = "Nuss To-Do List"
    @AppStorage("waterGoal") private var waterGoal: Double = 2.0
    @AppStorage("waterDrank") private var waterDrank: Double = 0.0
    @AppStorage("dailyNote") private var dailyNote = ""
    @AppStorage("isWaterReminderOn") private var isWaterReminderOn = false

    @State private var tasks: [Task] = {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            return decodedTasks
        }
        return []
    }() {
        didSet {
            if let encoded = try? JSONEncoder().encode(tasks) {
                UserDefaults.standard.set(encoded, forKey: "savedTasks")
            }
        }
    }

    @State private var newTaskTitle = ""
    @State private var newTaskDuration = 15
    @State private var selectedDate = Date()
    @State private var isEditingTitle = false
    @State private var showingGoalSettings = false

    @State private var activeTimerTaskID: UUID? = nil
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer? = nil

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray6), Color(red: 1.0, green: 0.94, blue: 0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        HStack {
                            if isEditingTitle {
                                TextField("Uygulama Adı", text: $appTitle, onCommit: {
                                    isEditingTitle = false
                                })
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .foregroundColor(.primary)
                                .frame(width: 200)
                            } else {
                                Text(appTitle)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.4))
                                    .onTapGesture {
                                        isEditingTitle = true
                                    }
                            }

                            Text("🌸")
                                .font(.title2)

                            Button(action: {
                                isEditingTitle.toggle()
                            }) {
                                Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle")
                                    .font(.title3)
                                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.5))
                            }
                        }
                        .padding(.top, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(-7...7, id: \.self) { offset in
                                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                                    VStack(spacing: 6) {
                                        Text(dayString(for: date, format: "EEE"))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(isSelected ? .white : .secondary)

                                        Text(dayString(for: date, format: "d"))
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : .primary)

                                        Text(dayString(for: date, format: "MMM"))
                                            .font(.system(size: 10))
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                    }
                                    .frame(width: 55, height: 75)
                                    .background(
                                        isSelected ?
                                        LinearGradient(colors: [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.9, green: 0.2, blue: 0.4)], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [Color.white, Color.white], startPoint: .top, endPoint: .bottom)
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: 6, x: 0, y: 3)
                                    .scaleEffect(isSelected ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Su Takibi", systemImage: "drop.fill")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.8))

                                Spacer()

                                Button(action: {
                                    showingGoalSettings.toggle()
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .sheet(isPresented: $showingGoalSettings) {
                                    VStack(spacing: 20) {
                                        Text("Günlük Su Hedefi Belirle")
                                            .font(.headline)
                                            .padding(.top)

                                        Picker("Hedef", selection: $waterGoal) {
                                            
                                            Text("1.5 Litre").tag(1.5)
                                            Text("2.0 Litre").tag(2.0)
                                            Text("2.5 Litre").tag(2.5)
                                            Text("3.0 Litre").tag(3.0)
                                            Text("3.5 Litre").tag(3.5)
                                            Text("4.0 Litre").tag(4.0)
                                        }
                                        .pickerStyle(.wheel)

                                        Button("Tamam") {
                                            showingGoalSettings = false
                                        }
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .cornerRadius(12)

                                        Spacer()
                                    }
                                    .presentationDetents([.height(250)])
                                }

                                Button(action: {
                                    waterDrank = max(0, waterDrank - 0.25)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.7))
                                }

                                Button(action: {
                                    waterDrank += 0.25
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9))
                                }
                            }

                            HStack {
                                Text(String(format: "Bugün: %.2f L / Hedef: %.2f L", waterDrank, waterGoal))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Button(action: {
                                    toggleWaterReminder()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isWaterReminderOn ? "bell.fill" : "bell.slash.fill")
                                        Text(isWaterReminderOn ? "Açık" : "Kapalı")
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isWaterReminderOn ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                                    .foregroundColor(isWaterReminderOn ? .blue : .secondary)
                                    .cornerRadius(8)
                                }
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 10)
                                        .cornerRadius(5)

                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: min(CGFloat(waterDrank / waterGoal) * geometry.size.width, geometry.size.width), height: 10)
                                        .cornerRadius(5)
                                        .animation(.easeInOut, value: waterDrank)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Günün Notu & Düşüncelerim", systemImage: "book.closed.fill")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.7))

                            ZStack(alignment: .topLeading) {
                                if dailyNote.isEmpty {
                                    Text("Bugün neler hissediyorsun, notların neler?")
                                        .foregroundColor(Color.gray)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }

                                TextEditor(text: $dailyNote)
                                    .frame(height: 90)
                                    .foregroundColor(.primary)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            TextField("Yeni görev adı...", text: $newTaskTitle)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)

                            HStack {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.5))
                                    Picker("Süre", selection: $newTaskDuration) {
                                        Text ("-").tag(0)
                                        Text("5 dk").tag(5)
                                        Text("10 dk").tag(10)
                                        Text("15 dk").tag(15)
                                        Text("20 dk").tag(20)
                                        Text("30 dk").tag(30)
                                        Text("45 dk").tag(45)
                                        Text("60 dk").tag(60)
                                    }
                                    .pickerStyle(.menu)
                                }

                                Spacer()

                                Button(action: addTask) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                        Text("Ekle")
                                    }
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(colors: [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.2, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bugünün Görevleri")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            let currentSelectedDateString = dateFormatter.string(from: selectedDate)
                            let filteredTasks = tasks.filter { $0.dateString == currentSelectedDateString }

                            if filteredTasks.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Text("🌻")
                                            .font(.system(size: 32))
                                        Text("Bugün için henüz görev yok, hadi bir tane ekle!")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 30)
                                    Spacer()
                                }
                            } else {
                                ForEach(filteredTasks) { task in
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            toggleCompletion(for: task)
                                        }) {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundColor(task.isCompleted ? .green : .gray)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.title)
                                                .font(.body)
                                                .strikethrough(task.isCompleted, color: .gray)
                                                .foregroundColor(task.isCompleted ? .gray : .primary)

                                            HStack(spacing: 6) {
                                                Image(systemName: "clock")
                                                    .font(.caption2)
                                              
                                                if activeTimerTaskID == task.id {
                                                    Text(formatTime(remainingSeconds))
                                                        .font(.caption)
                                                        .bold()
                                                        .foregroundColor(.orange)
                                                } else {
                                                    Text("\(task.durationMinutes) dk")
                                                        .font(.caption)
                                                }
                                            }
                                            .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Button(action: {
                                            if activeTimerTaskID == task.id {
                                                stopTimer()
                                            } else {
                                                startTimer(for: task)
                                            }
                                        }) {
                                            Image(systemName: activeTimerTaskID == task.id ? "stop.circle.fill" : "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(activeTimerTaskID == task.id ? .red : Color(red: 0.9, green: 0.4, blue: 0.6))
                                        }

                                        Button(action: {
                                            deleteTask(task)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                                    .padding(.horizontal)
                                }
                            }
                        }
                       
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onDisappear {
            stopTimer()
        }
    }

    func addTask() {
        let dateStr = dateFormatter.string(from: selectedDate)
        let newTask = Task(title: newTaskTitle, durationMinutes: newTaskDuration, dateString: dateStr)
        tasks.append(newTask)
        newTaskTitle = ""
    }

    func toggleCompletion(for task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }

    func deleteTask(_ task: Task) {
        if activeTimerTaskID == task.id {
            stopTimer()
        }
        tasks.removeAll(where: { $0.id == task.id })
    }

    func startTimer(for task: Task) {
        stopTimer()
        activeTimerTaskID = task.id
        remainingSeconds = task.durationMinutes * 60

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        activeTimerTaskID = nil
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    func dayString(for date: Date, format: String) -> String {
        dayFormatter.dateFormat = format
        return dayFormatter.string(from: date)
    }

    func toggleWaterReminder() {
        isWaterReminderOn.toggle()
        let center = UNUserNotificationCenter.current()
        if isWaterReminderOn {
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "Su İçme Vakti! 💧"
                    content.body = "Bugünkü su hedefine ulaşmak için bir bardak su içmeyi unutma!"
                    content.sound = .default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: true)
                    let request = UNNotificationRequest(identifier: "WaterReminder", content: content, trigger: trigger)
                    center.add(request)
                }
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["WaterReminder"])
        }
    }
}
