import SwiftUI
import CanakinStaffShared

struct RotaHeaderView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Month/Year header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Button(action: goToToday) {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            // Day range display
            HStack {
                Text(dayRangeString)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if calendar.isDateInToday(selectedDate) {
                    Text("TODAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            Divider()
        }
        .background(Color.staffBackground)
    }
    
    private var monthYearString: String {
        DateFormatter.monthYear.string(from: selectedDate)
    }
    
    private var dayRangeString: String {
        let day1 = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        let day3 = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        
        return "\(DateFormatter.shortDate.string(from: day1)) - \(DateFormatter.shortDate.string(from: day3))"
    }
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func goToToday() {
        let today = Date()

        selectedDate = today
    }
} 