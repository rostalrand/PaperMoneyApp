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
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                isPositive ? Color.green : Color.red,
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
