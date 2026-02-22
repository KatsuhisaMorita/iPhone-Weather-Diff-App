import Foundation

// MARK: - OpenMeteo API Response Models
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: DailyWeather
}

struct DailyWeather: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let apparentTemperatureMax: [Double]
    let apparentTemperatureMin: [Double]
    let precipitationProbabilityMax: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case apparentTemperatureMin = "apparent_temperature_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

// MARK: - App Models
struct Location {
    let name: String
    let latitude: Double
    let longitude: Double
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let dateString: String
    let maxTemp: Double
    let minTemp: Double
    let apparentMaxTemp: Double
    let apparentMinTemp: Double
    let rainProbability: Int
    let weatherCode: Int
    
    var isToday: Bool
}

struct WeatherDiff {
    let today: DailyForecast
    let yesterday: DailyForecast
    
    var maxTempDiff: Double {
        today.maxTemp - yesterday.maxTemp
    }
    
    var minTempDiff: Double {
        today.minTemp - yesterday.minTemp
    }
    
    var apparentMaxTempDiff: Double {
        today.apparentMaxTemp - yesterday.apparentMaxTemp
    }
    
    var apparentMinTempDiff: Double {
        today.apparentMinTemp - yesterday.apparentMinTemp
    }
}
