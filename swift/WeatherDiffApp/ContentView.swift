import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocationIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Location Picker
                        Picker("Location", selection: $selectedLocationIndex) {
                            ForEach(0..<weatherService.locations.count, id: \.self) { index in
                                Text(weatherService.locations[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedLocationIndex) { _ in
                            fetchData()
                        }
                        
                        // Main Content
                        if weatherService.isLoading {
                            ProgressView("天気情報を取得中...")
                                .foregroundColor(.white)
                                .padding(.top, 50)
                        } else if let error = weatherService.errorMessage {
                            errorView(error: error)
                        } else if let diff = weatherService.diffData {
                            adviceCard(diff: diff)
                            mainWeatherTable(diff: diff)
                            apparentWeatherTable(diff: diff)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Weather Diff Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchData) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            fetchData()
        }
        .preferredColorScheme(.dark)
    }
    
    private func fetchData() {
        let location = weatherService.locations[selectedLocationIndex]
        weatherService.fetchWeather(for: location)
    }
    
    // MARK: - Subviews
    
    private func errorView(error: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("エラーが発生しました")
                .font(.headline)
            Text(error)
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("再試行") {
                fetchData()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding()
    }
    
    private func generateAdvice(diff: WeatherDiff) -> String {
        let maxDiff = diff.todayMaxTempDiff
        let apparentMax = diff.today.apparentMaxTemp
        let rainProb = diff.today.rainProbability
        
        var diffText = ""
        if maxDiff <= -5 { diffText = "昨日と比べて大きく気温が下がります📉。" }
        else if maxDiff <= -2 { diffText = "昨日より少し涼しくなります。" }
        else if maxDiff >= 5 { diffText = "昨日から一気に気温が上がります📈。" }
        else if maxDiff >= 2 { diffText = "昨日より少し暖かくなります。" }
        else { diffText = "昨日とほぼ同じ気温です。" }
        
        var tempText = ""
        if apparentMax >= 30 { tempText = "厳しい暑さです🥵 薄着・半袖で十分！こまめな水分補給と熱中症対策を。" }
        else if apparentMax >= 25 { tempText = "汗ばむ暑さです☀️ 日中は半袖や薄手のシャツがおすすめです。" }
        else if apparentMax >= 18 { tempText = "過ごしやすい気候です🌱 長袖シャツや薄手のカーディガンで快適に過ごせます。" }
        else if apparentMax >= 12 { tempText = "少し肌寒く感じます🧥 セーターやジャケットなど羽織るものを持参しましょう。" }
        else if apparentMax >= 6 { tempText = "寒さを感じる気温です🧣 冬用コートなど暖かめの服装で防寒してください。" }
        else { tempText = "厳しい寒さです🥶 ダウンジャケットやマフラーなどで万全な防寒対策を！" }
        
        var rainText = ""
        if rainProb >= 50 { rainText = "\n☔ 高い確率(\(rainProb)%)で雨が降るため傘を忘れずに！" }
        else if rainProb >= 20 { rainText = "\n🌂 にわか雨の可能性(\(rainProb)%)があるので折りたたみ傘があると安心です。" }
        
        return "\(diffText) \(tempText)\(rainText)"
    }
    
    private func adviceCard(diff: WeatherDiff) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アドバイス")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.orange)
                .textCase(.uppercase)
            
            Text(generateAdvice(diff: diff))
                .font(.body)
                .foregroundColor(.black)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange, lineWidth: 2)
                .padding(.leading, 0) // Visual border effect similar to CSS border-left
        )
        // Simulate CSS border-left by overlaying a rectangle
        .overlay(
            Rectangle()
                .fill(Color.orange)
                .frame(width: 6)
                .padding(.leading, 0),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // Reusable view for table row content
    private func tableRow(label: String, yesterday: AnyView, today: AnyView, todayDiff: AnyView?, tomorrow: AnyView, tomorrowDiff: AnyView?) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            yesterday
                .frame(width: 60, alignment: .center)
            
            Spacer()
            
            VStack(spacing: 2) {
                today
                if let diff = todayDiff { diff }
            }
            .frame(width: 80, alignment: .center)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            VStack(spacing: 2) {
                tomorrow
                if let diff = tomorrowDiff { diff }
            }
            .frame(width: 80, alignment: .center)
        }
        .padding(.vertical, 8)
        .overlay(Divider().background(Color.white.opacity(0.2)), alignment: .bottom)
    }
    
    private func tempView(value: Double, color: Color) -> AnyView {
        AnyView(
            Text("\(String(format: "%.1f", value))°")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        )
    }
    
    private func tempDiffView(diff: Double) -> AnyView {
        AnyView(
            Text("(\(diff > 0 ? "+" : "")\(String(format: "%.1f", diff)))")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(diff > 0 ? Color(red: 1.0, green: 0.5, blue: 0.5) : Color(red: 0.5, green: 0.8, blue: 1.0))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .opacity(0.9)
        )
    }
    
    private func mainWeatherTable(diff: WeatherDiff) -> some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("").frame(width: 40)
                Spacer()
                Text("昨日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 60)
                Spacer()
                Text("今日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 80)
                Spacer()
                Text("明日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 80)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 8)
            
            // Weather Icon Row
            tableRow(
                label: "天気",
                yesterday: AnyView(weatherIcon(for: diff.yesterday.weatherCode).font(.title2).foregroundColor(.white).shadow(radius: 2)),
                today: AnyView(weatherIcon(for: diff.today.weatherCode).font(.title2).foregroundColor(.white).shadow(radius: 2)),
                todayDiff: nil,
                tomorrow: AnyView(weatherIcon(for: diff.tomorrow.weatherCode).font(.title2).foregroundColor(.white).shadow(radius: 2)),
                tomorrowDiff: nil
            )
            .padding(.horizontal, 8)
            
            // Max Temp Row
            tableRow(
                label: "最高\n気温",
                yesterday: tempView(value: diff.yesterday.maxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                today: tempView(value: diff.today.maxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                todayDiff: tempDiffView(diff: diff.todayMaxTempDiff),
                tomorrow: tempView(value: diff.tomorrow.maxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                tomorrowDiff: tempDiffView(diff: diff.tomorrowMaxTempDiff)
            )
            .padding(.horizontal, 8)
            
            // Min Temp Row
            tableRow(
                label: "最低\n気温",
                yesterday: tempView(value: diff.yesterday.minTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                today: tempView(value: diff.today.minTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                todayDiff: tempDiffView(diff: diff.todayMinTempDiff),
                tomorrow: tempView(value: diff.tomorrow.minTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                tomorrowDiff: tempDiffView(diff: diff.tomorrowMinTempDiff)
            )
            .padding(.horizontal, 8)
            
            // Rain Prob Row
            tableRow(
                label: "降水\n確率",
                yesterday: AnyView(Text("\(diff.yesterday.rainProbability)%").font(.subheadline).fontWeight(.bold).foregroundColor(Color(red: 0.6, green: 0.9, blue: 1.0))),
                today: AnyView(Text("\(diff.today.rainProbability)%").font(.subheadline).fontWeight(.bold).foregroundColor(Color(red: 0.6, green: 0.9, blue: 1.0))),
                todayDiff: nil,
                tomorrow: AnyView(Text("\(diff.tomorrow.rainProbability)%").font(.subheadline).fontWeight(.bold).foregroundColor(Color(red: 0.6, green: 0.9, blue: 1.0))),
                tomorrowDiff: nil
            )
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private func apparentWeatherTable(diff: WeatherDiff) -> some View {
        VStack(spacing: 0) {
            Text("体感温度")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 12)
            
            // Header Row
            HStack {
                Text("").frame(width: 40)
                Spacer()
                Text("昨日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 60)
                Spacer()
                Text("今日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 80)
                Spacer()
                Text("明日").font(.caption).foregroundColor(.white.opacity(0.8)).frame(width: 80)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 8)
            
            // Max Apparent Temp Row
            tableRow(
                label: "体感\n最高",
                yesterday: tempView(value: diff.yesterday.apparentMaxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                today: tempView(value: diff.today.apparentMaxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                todayDiff: tempDiffView(diff: diff.todayApparentMaxTempDiff),
                tomorrow: tempView(value: diff.tomorrow.apparentMaxTemp, color: Color(red: 1.0, green: 0.6, blue: 0.6)),
                tomorrowDiff: tempDiffView(diff: diff.tomorrowApparentMaxTempDiff)
            )
            .padding(.horizontal, 8)
            
            // Min Apparent Temp Row
            tableRow(
                label: "体感\n最低",
                yesterday: tempView(value: diff.yesterday.apparentMinTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                today: tempView(value: diff.today.apparentMinTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                todayDiff: tempDiffView(diff: diff.todayApparentMinTempDiff),
                tomorrow: tempView(value: diff.tomorrow.apparentMinTemp, color: Color(red: 0.6, green: 0.8, blue: 1.0)),
                tomorrowDiff: tempDiffView(diff: diff.tomorrowApparentMinTempDiff)
            )
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // Convert WMO Weather code to SF Symbols
    private func weatherIcon(for code: Int) -> Image {
        switch code {
        case 0:
            return Image(systemName: "sun.max.fill") // Clear sky
        case 1, 2, 3:
            return Image(systemName: "cloud.sun.fill") // Partly cloudy
        case 45, 48:
            return Image(systemName: "cloud.fog.fill") // Fog
        case 51, 53, 55, 56, 57:
            return Image(systemName: "cloud.drizzle.fill") // Drizzle
        case 61, 63, 65, 66, 67:
            return Image(systemName: "cloud.rain.fill") // Rain
        case 71, 73, 75, 77:
            return Image(systemName: "snowflake") // Snow
        case 80, 81, 82:
            return Image(systemName: "cloud.heavyrain.fill") // Showers
        case 85, 86:
            return Image(systemName: "cloud.snow.fill") // Snow showers
        case 95, 96, 99:
            return Image(systemName: "cloud.bolt.rain.fill") // Thunderstorm
        default:
            return Image(systemName: "cloud.fill")
        }
    }
}

#Preview {
    ContentView()
}
