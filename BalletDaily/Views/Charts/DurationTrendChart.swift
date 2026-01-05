//
//  DurationTrendChart.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  Phase 6: 时长趋势图表
//

import SwiftUI
import Charts

/// 时长趋势折线图
struct DurationTrendChart: View {
    let data: [DateValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.orange)
                Text("时长趋势")
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
            LineMark(
                x: .value("日期", item.date, unit: .day),
                y: .value("时长", item.value)
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("日期", item.date, unit: .day),
                y: .value("时长", item.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange.opacity(0.3), .orange.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("日期", item.date, unit: .day),
                y: .value("时长", item.value)
            )
            .foregroundStyle(.orange)
            .symbolSize(50)
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
        .chartYAxisLabel("时长 (小时)")
    }
    
    private var emptyChart: some View {
        Rectangle()
            .fill(Color.orange.opacity(0.1))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.orange.opacity(0.3))
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
        DateValue(date: Date().addingTimeInterval(-6*86400), value: 1.5),
        DateValue(date: Date().addingTimeInterval(-5*86400), value: 1.0),
        DateValue(date: Date().addingTimeInterval(-4*86400), value: 2.5),
        DateValue(date: Date().addingTimeInterval(-3*86400), value: 2.0),
        DateValue(date: Date().addingTimeInterval(-2*86400), value: 1.5),
        DateValue(date: Date().addingTimeInterval(-1*86400), value: 2.5),
        DateValue(date: Date(), value: 1.5)
    ]
    
    return DurationTrendChart(data: sampleData)
        .padding()
}

