//
//  ContentView.swift
//  MacroMeter
//
//  Created by Andy Huoy on 12/2/25.
//

import SwiftUI

// MARK: - Data Models

struct MacroGoal {
    var dailyCalories: Int
    var dailyProtein: Int
    var dailyCarbs: Int
    var dailyFat: Int
}

struct Meal: Identifiable {
    let id = UUID()
    var name: String
    var date: Date
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
}

// MARK: - View Model

class AppViewModel: ObservableObject {
    @Published var goals = MacroGoal(
        dailyCalories: 2200,
        dailyProtein: 140,
        dailyCarbs: 220,
        dailyFat: 70
    )
    
    @Published var meals: [Meal] = []
    
    init() {
        seedSampleData()
    }
    
    private func seedSampleData() {
        let today = Date()
        meals = [
            Meal(name: "Overnight Oats", date: today, calories: 430, protein: 30, carbs: 55, fat: 10),
            Meal(name: "Chicken & Rice Bowl", date: today, calories: 650, protein: 50, carbs: 70, fat: 15),
            Meal(name: "Greek Yogurt & Berries", date: today, calories: 220, protein: 18, carbs: 25, fat: 4)
        ]
    }
    
    // Helpers
    
    func meals(for date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func totals(for date: Date) -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        let dayMeals = meals(for: date)
        let calories = dayMeals.reduce(0) { $0 + $1.calories }
        let protein = dayMeals.reduce(0) { $0 + $1.protein }
        let carbs   = dayMeals.reduce(0) { $0 + $1.carbs }
        let fat     = dayMeals.reduce(0) { $0 + $1.fat }
        return (calories, protein, carbs, fat)
    }
}

// MARK: - Root Tab View (multiple screens)

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
            
            CalendarScreen()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            ProgressScreen()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
    }
}

// MARK: - Today Screen (Home)

struct TodayView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    DailySummaryCardView(
                        date: Date(),
                        totals: viewModel.totals(for: Date()),
                        goals: viewModel.goals
                    )
                    
                    MacroBarsSection(
                        totals: viewModel.totals(for: Date()),
                        goals: viewModel.goals
                    )
                    
                    TodayMealsSection(
                        meals: viewModel.meals(for: Date()),
                        onAddMeal: {
                            // TODO: present Add Meal screen
                            print("Add Meal tapped")
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Daily Summary Card

struct DailySummaryCardView: View {
    var date: Date
    var totals: (calories: Int, protein: Int, carbs: Int, fat: Int)
    var goals: MacroGoal
    
    // FIXED: formatter declared outside body
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()
    
    var body: some View {
        let calorieProgress = min(
            Double(totals.calories) / Double(max(goals.dailyCalories, 1)),
            1.0
        )
        
        HStack {
            // Calorie ring...
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                // FIXED here too — using static formatter
                Text(Self.dateFormatter.string(from: date))
                    .font(.headline)
                
                MacroRow(label: "Protein", value: totals.protein, goal: goals.dailyProtein)
                MacroRow(label: "Carbs", value: totals.carbs, goal: goals.dailyCarbs)
                MacroRow(label: "Fat", value: totals.fat, goal: goals.dailyFat)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}

struct MacroRow: View {
    let label: String
    let value: Int
    let goal: Int
    
    var percentageText: String {
        guard goal > 0 else { return "0%" }
        let pct = Int((Double(value) / Double(goal)) * 100)
        return "\(pct)%"
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(value)g / \(goal)g")
                .font(.subheadline.monospacedDigit())
            Text(percentageText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Macro Bars Section

struct MacroBarsSection: View {
    var totals: (calories: Int, protein: Int, carbs: Int, fat: Int)
    var goals: MacroGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Breakdown")
                .font(.headline)
            
            MacroBar(label: "Protein", value: totals.protein, goal: goals.dailyProtein)
            MacroBar(label: "Carbs", value: totals.carbs, goal: goals.dailyCarbs)
            MacroBar(label: "Fat", value: totals.fat, goal: goals.dailyFat)
        }
    }
}

struct MacroBar: View {
    let label: String
    let value: Int
    let goal: Int
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(value) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value) / \(goal) g")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
    }
}

// MARK: - Today's Meals

struct TodayMealsSection: View {
    var meals: [Meal]
    var onAddMeal: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Meals")
                    .font(.headline)
                Spacer()
                Button(action: onAddMeal) {
                    Label("Add Meal", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .font(.subheadline)
            }
            
            if meals.isEmpty {
                Text("No meals logged yet. Tap “Add Meal” to get started.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(meals) { meal in
                    MealRow(meal: meal)
                }
            }
        }
    }
}

struct MealRow: View {
    var meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.name)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                Text("\(meal.calories) kcal")
                    .font(.caption.monospacedDigit())
                Text("P \(meal.protein)g")
                    .font(.caption.monospacedDigit())
                Text("C \(meal.carbs)g")
                    .font(.caption.monospacedDigit())
                Text("F \(meal.fat)g")
                    .font(.caption.monospacedDigit())
            }
            .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Placeholder Screens For Other Tabs

struct CalendarScreen: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            Text("Calendar view coming soon")
                .padding()
                .navigationTitle("Calendar")
        }
    }
}

struct ProgressScreen: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            Text("Progress charts coming soon")
                .padding()
                .navigationTitle("Progress")
        }
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
        .environmentObject(AppViewModel())
}
