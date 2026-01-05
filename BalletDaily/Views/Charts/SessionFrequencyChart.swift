//
//  SessionFrequencyChart.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  Phase 6: 课程频率图表
//

import SwiftUI
import Charts

/// 课程频率柱状图
struct SessionFrequencyChart: View {
    let data: [DateValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("课程频率")
                    .font(.headline)
                Spacer()
            }
            
            if data.isEmpty {
                emptyChart
            } else {
                chart
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var chart: some View {
        Chart(data) { item in
            BarMark(
                x: .value("日期", item.date, unit: .day),
                y: .value("课程数", item.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
        .chartXAxisLabel("日期")
        .chartYAxisLabel("课程数")
    }
    
    private var emptyChart: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.1))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue.opacity(0.3))
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            )
            .cornerRadius(8)
    }
}

#Preview {
    let sampleData = [
        DateValue(date: Date().addingTimeInterval(-6*86400), value: 2),
        DateValue(date: Date().addingTimeInterval(-5*86400), value: 1),
        DateValue(date: Date().addingTimeInterval(-4*86400), value: 3),
        DateValue(date: Date().addingTimeInterval(-3*86400), value: 2),
        DateValue(date: Date().addingTimeInterval(-2*86400), value: 1),
        DateValue(date: Date().addingTimeInterval(-1*86400), value: 2),
        DateValue(date: Date(), value: 1)
    ]
    
    return SessionFrequencyChart(data: sampleData)
        .padding()
}

