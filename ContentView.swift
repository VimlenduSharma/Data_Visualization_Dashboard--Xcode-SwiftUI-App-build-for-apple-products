import SwiftUI
import Charts
import UniformTypeIdentifiers

struct DataPoint: Identifiable, Codable {
    let id: UUID = UUID()
    let timestamp: Date
    let value: Double
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, value
    }
    
    init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        value = try container.decode(Double.self, forKey: .value)
    }
}
class DataModel: ObservableObject {
    @Published var dataPoints: [DataPoint] = [
        DataPoint(timestamp: Date().addingTimeInterval(-3600), value: 10),
        DataPoint(timestamp: Date().addingTimeInterval(-1800), value: 20),
        DataPoint(timestamp: Date(), value: 15)
    ]
    
    func addDataPoint(value: Double) {
        let newPoint = DataPoint(timestamp: Date(), value: value)
        dataPoints.append(newPoint)
    }
    
    func updateDataPoints(with newPoints: [DataPoint]) {
        DispatchQueue.main.async {
            self.dataPoints = newPoints
        }
    }
    
    func minMaxTimestamps() -> (Date, Date)? {
        guard let minDate = dataPoints.map(\.timestamp).min(),
              let maxDate = dataPoints.map(\.timestamp).max()
        else {
            return nil
        }
        return (minDate, maxDate)
    }
}

enum ChartType: String, CaseIterable, Identifiable {
    case line = "Line"
    case bar = "Bar"
    case pie = "Pie"
    
    var id: String { self.rawValue }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.8))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .padding([.horizontal, .top])
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}

struct ChartSwitcher: View {
    let selectedChart: ChartType
    let dataPoints: [DataPoint]
    
    var body: some View {
        Group {
            switch selectedChart {
            case .line:
                LineChartView(dataPoints: dataPoints)
                    .transition(.opacity)
            case .bar:
                BarChartView(dataPoints: dataPoints)
                    .transition(.opacity)
            case .pie:
                PieChartView(dataPoints: dataPoints)
                    .transition(.opacity)
            }
        }
    }
}

struct StatisticsView: View {
    let dataPoints: [DataPoint]
    
    private var count: Int {
        dataPoints.count
    }
    private var total: Double {
        dataPoints.reduce(0) { $0 + $1.value }
    }
    private var average: Double {
        count > 0 ? total / Double(count) : 0
    }
    private var minValue: Double {
        dataPoints.map(\.value).min() ?? 0
    }
    private var maxValue: Double {
        dataPoints.map(\.value).max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Data Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Count: \(count)")
            Text(String(format: "Min: %.2f", minValue))
            Text(String(format: "Max: %.2f", maxValue))
            Text(String(format: "Average: %.2f", average))
        }
        .font(.subheadline)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .cardStyle()
    }
}

struct ContentView: View {
    @StateObject private var model = DataModel()
    
    @State private var inputValue: String = ""
    @State private var selectedChart: ChartType = .line
    
    @State private var filterActive = false
    @State private var filterStartDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var filterEndDate: Date = Date()
    
    @State private var showingImportOptions = false
    @State private var showingFileImporter = false
    @State private var showingAPIImporter = false
    @State private var apiURL: String = ""
    

    var filteredDataPoints: [DataPoint] {
        model.dataPoints.filter {
            $0.timestamp >= filterStartDate && $0.timestamp <= filterEndDate
        }
    }
    
    var displayedDataPoints: [DataPoint] {
        filterActive ? filteredDataPoints : model.dataPoints
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                       
                        Picker("Chart Type", selection: $selectedChart) {
                            ForEach(ChartType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 3)
                        .padding(.top)
    
                        .onChange(of: selectedChart) { newValue in
                            withAnimation(.easeInOut) {
                        
                            }
                        }
                        
                        ChartSwitcher(selectedChart: selectedChart, dataPoints: displayedDataPoints)
                            .frame(height: 300)
                            .padding()
                            .cardStyle()
                        
    
                        GroupBox(label:
                            Text("Filter Data by Date Range")
                                .font(.headline)
                                .foregroundColor(.primary)
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Apply Date Filter", isOn: $filterActive)
                                    .padding(.bottom, 4)
                                
                                HStack {
                                    DatePicker(
                                        "Start Date",
                                        selection: $filterStartDate,
                                        displayedComponents: .date
                                    )
                                    DatePicker(
                                        "End Date",
                                        selection: $filterEndDate,
                                        displayedComponents: .date
                                    )
                                }
                                
                                Button("Reset Filter to Full Range") {
                                    if let (minDate, maxDate) = model.minMaxTimestamps() {
                                        filterStartDate = minDate
                                        filterEndDate = maxDate
                                    }
                                    filterActive = true
                                }
                                .buttonStyle(.bordered)
                                .padding(.top, 4)
                                
                               
                                Text("Filtered Chart Preview")
                                    .font(.subheadline).bold()
                                    .foregroundColor(.secondary)
                                    .padding(.top, 6)
                                
                                ChartSwitcher(selectedChart: selectedChart, dataPoints: filteredDataPoints)
                                    .frame(height: 200)
                                    .padding()
                                    .cardStyle()
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        StatisticsView(dataPoints: displayedDataPoints)
                        HStack {
                            TextField("Enter value", text: $inputValue)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading)
                            
                            Button("Add") {
                                if let value = Double(inputValue) {
                                    model.addDataPoint(value: value)
                                    inputValue = ""
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.vertical)
                        
                        Spacer(minLength: 20)
                    }
                    .navigationTitle("Data Visualization")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button("Import Data") {
                            showingImportOptions = true
                        }
                    }
                    .confirmationDialog("Import Data", isPresented: $showingImportOptions, titleVisibility: .visible) {
                        Button("Import from File") { showingFileImporter = true }
                        Button("Import from API") { showingAPIImporter = true }
                        Button("Cancel", role: .cancel) { }
                    }
                    .fileImporter(
                        isPresented: $showingFileImporter,
                        allowedContentTypes: [UTType.json, UTType.commaSeparatedText],
                        allowsMultipleSelection: false
                    ) { result in
                        do {
                            guard let selectedFile = try result.get().first else { return }
                            let resourceValues = try selectedFile.resourceValues(forKeys: [.contentTypeKey])
                            guard let fileType = resourceValues.contentType else {
                                print("Could not determine file type.")
                                return
                            }
                            let fileData = try Data(contentsOf: selectedFile)
                            
                            switch fileType {
                            case UTType.json:
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                let importedPoints = try decoder.decode([DataPoint].self, from: fileData)
                                model.updateDataPoints(with: importedPoints)
                                
                            case UTType.commaSeparatedText:
                                if let importedPoints = parseCSV(data: fileData) {
                                    model.updateDataPoints(with: importedPoints)
                                } else {
                                    print("Failed to parse CSV data.")
                                }
                                
                            default:
                                print("Unsupported file type: \(fileType)")
                            }
                        } catch {
                            print("Error importing file: \(error)")
                        }
                    }
                    .sheet(isPresented: $showingAPIImporter) {
                        VStack(spacing: 20) {
                            Text("Enter API URL")
                                .font(.headline)
                            
                            TextField("https://example.com/data.json", text: $apiURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            Button("Fetch Data") {
                                fetchDataFromAPI(urlString: apiURL)
                                showingAPIImporter = false
                                apiURL = ""
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Cancel") {
                                showingAPIImporter = false
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func fetchDataFromAPI(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching API data: \(error)")
                return
            }
            guard let data = data else {
                print("No data received from API")
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let importedPoints = try decoder.decode([DataPoint].self, from: data)
                model.updateDataPoints(with: importedPoints)
            } catch {
                print("Error decoding API data: \(error)")
            }
        }.resume()
    }
    private func parseCSV(data: Data) -> [DataPoint]? {
        guard let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        var points: [DataPoint] = []
        let lines = content.components(separatedBy: .newlines)
        var startIndex = 0
        if let firstLine = lines.first?.lowercased(),
           firstLine.contains("timestamp") {
            startIndex = 1
        }
        
        for i in startIndex..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let columns = line.components(separatedBy: ",")
            guard columns.count == 2 else { continue }
            
            let rawDate = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let rawValue = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let dateFormatter = ISO8601DateFormatter()
            guard let date = dateFormatter.date(from: rawDate),
                  let value = Double(rawValue) else {
                continue
            }
            
            points.append(DataPoint(timestamp: date, value: value))
        }
        
        return points
    }
}

struct LineChartView: View {
    let dataPoints: [DataPoint]
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
    }
}

struct BarChartView: View {
    let dataPoints: [DataPoint]
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                BarMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
    }
}

struct PieChartView: View {
    let dataPoints: [DataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let total = dataPoints.reduce(0) { $0 + $1.value }
            ZStack {
                ForEach(dataPoints.indices, id: \.self) { index in
                    let startAngle = angle(for: index, total: total)
                    let endAngle = angle(for: index + 1, total: total)
                    
                    PieSlice(startAngle: startAngle, endAngle: endAngle)
                        .fill(color(for: index))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    func angle(for index: Int, total: Double) -> Angle {
        let sum = dataPoints.prefix(index).reduce(0) { $0 + $1.value }
        return Angle(degrees: (sum / max(total, 1)) * 360)
    }
    
    func color(for index: Int) -> Color {
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .yellow]
        return colors[index % colors.count]
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - Angle(degrees: 90),
            endAngle: endAngle - Angle(degrees: 90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

