//
//  DistributionChart.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  Phase 6: 分布图表
//

import SwiftUI
import Charts

/// 分布图表（横向条形图）
struct DistributionChart: View {
    let title: String
    let icon: String
    let color: Color
    let data: [NameValue]
    let maxItems: Int
    
    init(
        title: String,
        icon: String,
        color: Color,
        data: [NameValue],
        maxItems: Int = 5
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.data = Array(data.prefix(maxItems))
        self.maxItems = maxItems
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
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
                x: .value("数量", item.value),
                y: .value("名称", item.name)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
            .annotation(position: .trailing) {
                Text("\(item.value)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
            }
        }
        .frame(height: CGFloat(max(data.count * 50, 150)))
    }
    
    private var emptyChart: some View {
        Rectangle()
            .fill(color.opacity(0.1))
            .frame(height: 150)
            .overlay(
                VStack {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(color.opacity(0.3))
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
        NameValue(name: "芭蕾基础", value: 15),
        NameValue(name: "芭蕾进阶", value: 10),
        NameValue(name: "现代舞", value: 8),
        NameValue(name: "古典芭蕾", value: 5),
        NameValue(name: "爵士舞", value: 3)
    ]
    
    return DistributionChart(
        title: "课程分布",
        icon: "chart.pie.fill",
        color: .green,
        data: sampleData
    )
    .padding()
}

