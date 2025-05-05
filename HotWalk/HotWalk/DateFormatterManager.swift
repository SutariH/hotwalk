import Foundation

class DateFormatterManager {
    static let shared = DateFormatterManager()
    
    private init() {
        // Configure formatters
        dailyKeyFormatter.dateFormat = "yyyy-MM-dd"
        dailyKeyFormatter.timeZone = TimeZone.current
        dailyKeyFormatter.locale = Locale.current
        
        readableDateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        readableDateFormatter.timeZone = TimeZone.current
        readableDateFormatter.locale = Locale.current
        
        monthYearFormatter.dateFormat = "MMMM yyyy"
        monthYearFormatter.timeZone = TimeZone.current
        monthYearFormatter.locale = Locale.current
    }
    
    // MARK: - Formatters
    
    let dailyKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
    
    let readableDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
    
    let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        return formatter
    }()
} 