import Foundation

class WeatherService: ObservableObject {
    @Published var diffData: WeatherDiff?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Locations
    let locations = [
        Location(name: "大倉山 (Okurayama)", latitude: 35.53, longitude: 139.63),
        Location(name: "東京 (Tokyo)", latitude: 35.68, longitude: 139.76)
    ]
    
    func fetchWeather(for location: Location) {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max&timezone=Asia%2FTokyo&past_days=1&forecast_days=2"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(WeatherResponse.self, from: data)
                    
                    guard result.daily.time.count >= 2 else {
                        self?.errorMessage = "Not enough data"
                        return
                    }
                    
                    let yesterday = DailyForecast(
                        dateString: result.daily.time[0],
                        maxTemp: result.daily.temperature2mMax[0],
                        minTemp: result.daily.temperature2mMin[0],
                        apparentMaxTemp: result.daily.apparentTemperatureMax[0],
                        apparentMinTemp: result.daily.apparentTemperatureMin[0],
                        rainProbability: result.daily.precipitationProbabilityMax[0],
                        weatherCode: result.daily.weatherCode[0],
                        isToday: false
                    )
                    
                    let today = DailyForecast(
                        dateString: result.daily.time[1],
                        maxTemp: result.daily.temperature2mMax[1],
                        minTemp: result.daily.temperature2mMin[1],
                        apparentMaxTemp: result.daily.apparentTemperatureMax[1],
                        apparentMinTemp: result.daily.apparentTemperatureMin[1],
                        rainProbability: result.daily.precipitationProbabilityMax[1],
                        weatherCode: result.daily.weatherCode[1],
                        isToday: true
                    )
                    
                    self?.diffData = WeatherDiff(today: today, yesterday: yesterday)
                    
                } catch {
                    self?.errorMessage = "Data parsing error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
