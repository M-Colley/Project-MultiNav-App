import Foundation
import TactileMapCore

/// Fits the occupied coordinate space, leaving physical stroke/marker sizes to
/// the existing renderer. All layers share one transform for drawing and hits.
enum StudyMapLayout {
    static func fittedLayers(_ layers: [TactileMapLayer]) -> [TactileMapLayer] {
        let points = layers.flatMap { $0.document.features }.flatMap { coordinates($0.geometry) }
        guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(),
              points.allSatisfy({ $0.x.isFinite && $0.y.isFinite }),
              maxX > minX, maxY > minY else { return layers }
        let bounds = TactileMapBounds(width: maxX - minX, height: maxY - minY)
        func shift(_ point: TactileCoordinate) -> TactileCoordinate {
            TactileCoordinate(x: point.x - minX, y: point.y - minY)
        }
        return layers.map { layer in
            let features = layer.document.features.map { feature in
                let geometry: TactileGeometry
                switch feature.geometry {
                case .point(let point): geometry = .point(shift(point))
                case .lineString(let points): geometry = .lineString(points.map(shift))
                case .polygon(let points): geometry = .polygon(points.map(shift))
                }
                return MapElement(id: feature.id, elementType: feature.elementType,
                                  geometry: geometry, properties: feature.properties)
            }
            return TactileMapLayer(id: layer.id, document: TactileMapDocument(
                version: layer.document.version, bounds: bounds, features: features,
                metadata: layer.document.metadata
            ), isInteractable: layer.isInteractable)
        }
    }

    private static func coordinates(_ geometry: TactileGeometry) -> [TactileCoordinate] {
        switch geometry {
        case .point(let point): return [point]
        case .lineString(let points), .polygon(let points): return points
        }
    }
}
