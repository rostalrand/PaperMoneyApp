import SwiftUI

public enum ChartDisplayMode: String, CaseIterable, Identifiable {
    case line = "Line"
    case candles = "Candles"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .candles: return "chart.bar.xaxis"
        }
    }
}

public struct InteractiveChartView: View {
    public let points: [ChartDataPoint]
    public let candles: [CandlestickPoint]
    public let isPositive: Bool
    @Binding public var displayMode: ChartDisplayMode
    @Binding public var externalSelectedPoint: ChartDataPoint?

    @State private var dragLocation: CGPoint? = nil
    @State private var selectedPoint: ChartDataPoint? = nil
    @State private var selectedCandle: CandlestickPoint? = nil
    @State private var lastScrubIndex: Int? = nil

    public init(
        points: [ChartDataPoint],
        candles: [CandlestickPoint] = [],
        isPositive: Bool,
        displayMode: Binding<ChartDisplayMode> = .constant(.line),
        externalSelectedPoint: Binding<ChartDataPoint?> = .constant(nil)
    ) {
        self.points = points
        self.candles = candles
        self.isPositive = isPositive
        self._displayMode = displayMode
        self._externalSelectedPoint = externalSelectedPoint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top Header: Scrub detail with fixed reserved height to eliminate chart vertical jump
            HStack {
                if displayMode == .candles, let candle = selectedCandle {
                    HStack(spacing: 8) {
                        Text("O: $\(formatPrice(candle.open))")
                        Text("H: $\(formatPrice(candle.high))")
                        Text("L: $\(formatPrice(candle.low))")
                        Text("C: $\(formatPrice(candle.close))")
                        Spacer()
                        Text(formatDate(candle.timestamp))
                    }
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundColor(candle.isBullish ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                    .padding(.horizontal, 4)
                } else if externalSelectedPoint == nil, let selected = selectedPoint {
                    HStack {
                        Text("$\(String(format: "%.2f", selected.price))")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(AppTheme.Colors.headline)
                        Spacer()
                        Text(formatDate(selected.timestamp))
                            .font(.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    .padding(.horizontal, 4)
                } else {
                    Spacer().frame(height: 18)
                }
            }
            .frame(height: 18)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack(alignment: .topLeading) {
                    if displayMode == .line || candles.isEmpty {
                        // Gradient Fill Area
                        chartAreaPath(width: width, height: height)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss).opacity(0.18),
                                        (isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss).opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Line Stroke
                        chartLinePath(width: width, height: height)
                            .stroke(
                                isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss,
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                            )
                    } else {
                        // Candlestick Charts (OHLC)
                        candlesticksView(width: width, height: height)
                    }

                    // Scrubbing Indicator
                    if let drag = dragLocation {
                        Path { path in
                            path.move(to: CGPoint(x: drag.x, y: 0))
                            path.addLine(to: CGPoint(x: drag.x, y: height))
                        }
                        .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        if displayMode == .line, let selected = selectedPoint {
                            let yPos = getYPosition(for: selected.price, height: height)
                            Circle()
                                .fill(isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: (isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss).opacity(0.6), radius: 4)
                                .position(x: drag.x, y: yPos)
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragLocation = value.location
                            updateSelectedPoint(at: value.location.x, width: width)
                        }
                        .onEnded { _ in
                            dragLocation = nil
                            selectedPoint = nil
                            selectedCandle = nil
                            lastScrubIndex = nil
                            externalSelectedPoint = nil
                        }
                )
            }
        }
    }

    // MARK: - Candlesticks Drawing
    private func candlesticksView(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, size in
            guard !candles.isEmpty else { return }
            let stepX = size.width / CGFloat(candles.count)
            let candleWidth = max(2.0, stepX * 0.70)

            for (index, candle) in candles.enumerated() {
                let x = CGFloat(index) * stepX + (stepX / 2)
                let highY = getYPosition(for: candle.high, height: size.height)
                let lowY = getYPosition(for: candle.low, height: size.height)
                let openY = getYPosition(for: candle.open, height: size.height)
                let closeY = getYPosition(for: candle.close, height: size.height)

                let color = candle.isBullish ? AppTheme.Colors.gain : AppTheme.Colors.loss

                // Draw Wick
                var wick = Path()
                wick.move(to: CGPoint(x: x, y: highY))
                wick.addLine(to: CGPoint(x: x, y: lowY))
                context.stroke(wick, with: .color(color), lineWidth: 1.5)

                // Draw Candle Body
                let topY = min(openY, closeY)
                let bodyHeight = max(2.0, abs(closeY - openY))
                let bodyRect = CGRect(x: x - (candleWidth / 2), y: topY, width: candleWidth, height: bodyHeight)
                context.fill(Path(roundedRect: bodyRect, cornerRadius: 1), with: .color(color))
            }
        }
    }

    private var prices: [Double] {
        if displayMode == .candles && !candles.isEmpty {
            return candles.flatMap { [$0.high, $0.low] }
        }
        return points.map { $0.price }
    }

    private var minPrice: Double {
        prices.min() ?? 0
    }

    private var maxPrice: Double {
        prices.max() ?? 1
    }

    private func getYPosition(for price: Double, height: CGFloat) -> CGFloat {
        let range = max(maxPrice - minPrice, 0.001)
        let normalized = CGFloat((price - minPrice) / range)
        return height - (normalized * (height - 20) + 10)
    }

    private func chartLinePath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let stepX = width / CGFloat(points.count - 1)

        var cgPoints: [CGPoint] = []
        for (index, point) in points.enumerated() {
            let x = CGFloat(index) * stepX
            let y = getYPosition(for: point.price, height: height)
            cgPoints.append(CGPoint(x: x, y: y))
        }

        path.move(to: cgPoints[0])
        for i in 1..<cgPoints.count {
            let p0 = cgPoints[i - 1]
            let p1 = cgPoints[i]
            let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            let controlPoint1 = CGPoint(x: (midPoint.x + p0.x) / 2, y: p0.y)
            let controlPoint2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
            path.addCurve(to: p1, control1: controlPoint1, control2: controlPoint2)
        }
        return path
    }

    private func chartAreaPath(width: CGFloat, height: CGFloat) -> Path {
        var path = chartLinePath(width: width, height: height)
        guard points.count > 1 else { return path }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    private func updateSelectedPoint(at xPos: CGFloat, width: CGFloat) {
        if displayMode == .candles && !candles.isEmpty {
            let clampedX = max(0, min(width, xPos))
            let fraction = clampedX / width
            let index = Int(round(fraction * CGFloat(candles.count - 1)))
            let safeIndex = max(0, min(candles.count - 1, index))
            selectedCandle = candles[safeIndex]
            if lastScrubIndex != safeIndex {
                lastScrubIndex = safeIndex
                HapticsService.shared.selection()
            }
        } else if points.count > 1 {
            let clampedX = max(0, min(width, xPos))
            let fraction = clampedX / width
            let index = Int(round(fraction * CGFloat(points.count - 1)))
            let safeIndex = max(0, min(points.count - 1, index))
            selectedPoint = points[safeIndex]
            externalSelectedPoint = points[safeIndex]
            if lastScrubIndex != safeIndex {
                lastScrubIndex = safeIndex
                HapticsService.shared.selection()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
}
