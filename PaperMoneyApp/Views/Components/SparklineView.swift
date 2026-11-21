import SwiftUI

public struct SparklineView: View {
    public let data: [Double]
    public let isPositive: Bool

    public init(data: [Double], isPositive: Bool) {
        self.data = data
        self.isPositive = isPositive
    }

    public var body: some View {
        GeometryReader { geometry in
            let points = normalize(data: data, width: geometry.size.width, height: geometry.size.height)
            
            Path { path in
                guard points.count > 1 else { return }
                path.move(to: points[0])
                for i in 1..<points.count {
                    let p0 = points[i - 1]
                    let p1 = points[i]
                    let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                    let controlPoint1 = CGPoint(x: (midPoint.x + p0.x) / 2, y: p0.y)
                    let controlPoint2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
                    path.addCurve(to: p1, control1: controlPoint1, control2: controlPoint2)
                }
            }
            .stroke(
                isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss,
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func normalize(data: [Double], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard data.count > 1 else { return [] }
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 1
        let range = max(maxVal - minVal, 0.001)

        let stepX = width / CGFloat(data.count - 1)
        return data.enumerated().map { index, val in
            let x = CGFloat(index) * stepX
            let normalizedY = CGFloat((val - minVal) / range)
            let y = height - (normalizedY * (height - 4) + 2)
            return CGPoint(x: x, y: y)
        }
    }
}
