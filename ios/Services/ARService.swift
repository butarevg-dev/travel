import Foundation
import ARKit
import SceneKit
import Combine
import AVFoundation

@MainActor
class ARService: ObservableObject {
    static let shared = ARService()
    
    // MARK: - Published Properties
    @Published var isARSessionActive = false
    @Published var currentARMode: ARMode = .none
    @Published var detectedPOIs: [ARPOI] = []
    @Published var currentRoute: ARRoute?
    @Published var error: String?
    @Published var sessionState = ARSessionState(
        isActive: false,
        trackingState: .notAvailable,
        cameraTransform: nil,
        detectedPOIs: [],
        error: nil,
        capabilities: ARCapabilities()
    )
    @Published var uiState = ARUIState(
        showPOICards: true,
        showNavigationElements: false,
        showControls: true,
        showInfoPanel: false,
        selectedPOI: nil,
        activeQuests: []
    )
    @Published var navigationState = ARNavigationState(
        isActive: false,
        currentRoute: nil,
        nextWaypoint: nil,
        distanceToNext: 0,
        direction: 0,
        estimatedTime: 0,
        turnByTurnInstructions: []
    )
    @Published var audioState = ARAudioState(
        isPlaying: false,
        currentPOI: nil,
        audioURL: nil,
        volume: 1.0,
        isSpatial: false,
        position: nil
    )
    
    // MARK: - Private Properties
    private var arSession: ARSession?
    private var arConfiguration: ARWorldTrackingConfiguration?
    private var imageAnchors: [ARImageAnchor] = []
    private var arSceneView: ARSCNView?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Dependencies
    private let gamificationService = GamificationService.shared
    private let audioService = AudioPlayerService.shared
    private let locationService = LocationService.shared
    private let firestoreService = FirestoreService.shared
    private let localContentService = LocalContentService.shared
    
    // MARK: - AR Components
    private var poiNodes: [String: SCNNode] = [:]
    private var navigationNodes: [String: SCNNode] = [:]
    private var audioNodes: [String: SCNNode] = [:]
    private var imageTrackingSet: Set<ARReferenceImage> = []
    
    // MARK: - Performance Monitoring
    private var performanceMonitor = ARPerformanceMonitor()
    private var sessionStartTime: Date?
    private var frameCount = 0
    private var lastFrameTime: Date?
    
    private init() {
        setupCapabilities()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    private func setupCapabilities() {
        var capabilities = ARCapabilities()
        capabilities.isARKitSupported = ARWorldTrackingConfiguration.isSupported
        capabilities.isImageTrackingSupported = ARImageTrackingConfiguration.isSupported
        capabilities.isObjectScanningSupported = ARObjectScanningConfiguration.isSupported
        capabilities.isFaceTrackingSupported = ARFaceTrackingConfiguration.isSupported
        capabilities.supportsWorldTracking = ARWorldTrackingConfiguration.isSupported
        capabilities.supportsPlaneDetection = true
        capabilities.maxImageTracking = 4
        
        // Определение производительности устройства
        if ProcessInfo.processInfo.processorCount >= 6 {
            capabilities.devicePerformance = .excellent
        } else if ProcessInfo.processInfo.processorCount >= 4 {
            capabilities.devicePerformance = .good
        } else {
            capabilities.devicePerformance = .poor
        }
        
        sessionState.capabilities = capabilities
    }
    
    private func setupBindings() {
        // Связывание с геймификацией
        gamificationService.$gameState
            .sink { [weak self] gameState in
                self?.updateARQuests()
            }
            .store(in: &cancellables)
        
        // Связывание с аудио сервисом
        audioService.$isPlaying
            .sink { [weak self] isPlaying in
                self?.audioState.isPlaying = isPlaying
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Session Management
    func startARSession(mode: ARMode) {
        guard sessionState.capabilities.isARKitSupported else {
            error = ARError.deviceNotSupported.errorDescription
            return
        }
        
        currentARMode = mode
        sessionStartTime = Date()
        
        // Настройка AR конфигурации
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        configuration.environmentTexturing = .automatic
        
        // Настройка image tracking если нужно
        if mode == .poiDetection || mode == .quest {
            setupImageTracking(configuration: configuration)
        }
        
        // Запуск сессии
        arSession?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isARSessionActive = true
        sessionState.isActive = true
        
        // Логирование события
        logAREvent(AREvent(
            type: .sessionStarted,
            timestamp: Date(),
            poiId: nil,
            routeId: nil,
            questId: nil,
            metadata: ["mode": mode.rawValue]
        ))
        
        // Запуск мониторинга производительности
        performanceMonitor.startMonitoring()
    }
    
    func stopARSession() {
        arSession?.pause()
        isARSessionActive = false
        sessionState.isActive = false
        
        // Очистка AR сцены
        clearARScene()
        
        // Логирование события
        logAREvent(AREvent(
            type: .sessionEnded,
            timestamp: Date(),
            poiId: nil,
            routeId: nil,
            questId: nil,
            metadata: [:]
        ))
        
        // Остановка мониторинга производительности
        performanceMonitor.stopMonitoring()
        
        // Обновление статистики
        updateARStatistics()
    }
    
    func setARView(_ arView: ARSCNView) {
        self.arSceneView = arView
        arView.delegate = self
        arView.session.delegate = self
        arView.automaticallyUpdatesLighting = true
        arView.autoenablesDefaultLighting = true
    }
    
    // MARK: - Image Tracking Setup
    private func setupImageTracking(configuration: ARWorldTrackingConfiguration) {
        // Загрузка reference images для POI
        Task {
            do {
                let pois = try await firestoreService.fetchPOIList()
                let referenceImages = await createReferenceImages(from: pois)
                
                await MainActor.run {
                    configuration.detectionImages = referenceImages
                    self.imageTrackingSet = Set(referenceImages)
                }
            } catch {
                // Fallback на локальные данные
                let pois = localContentService.getPOIs()
                Task {
                    let referenceImages = await createReferenceImages(from: pois)
                    await MainActor.run {
                        configuration.detectionImages = referenceImages
                        self.imageTrackingSet = Set(referenceImages)
                    }
                }
            }
        }
    }
    
    private func createReferenceImages(from pois: [POI]) async -> Set<ARReferenceImage> {
        var referenceImages: Set<ARReferenceImage> = []
        
        for poi in pois {
            // Создание placeholder изображения для POI
            if let image = createPlaceholderImage(for: poi) {
                let referenceImage = ARReferenceImage(
                    image.cgImage!,
                    orientation: .up,
                    physicalWidth: 0.1 // 10 см
                )
                referenceImage.name = poi.id
                referenceImages.insert(referenceImage)
            }
        }
        
        return referenceImages
    }
    
    private func createPlaceholderImage(for poi: POI) -> UIImage? {
        // Создание простого изображения с названием POI
        let size = CGSize(width: 512, height: 512)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let text = poi.title
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - POI Detection and Management
    func handlePOIDetection(_ poi: POI, anchor: ARAnchor) {
        let arPOI = ARPOI(
            id: poi.id,
            poi: poi,
            anchor: anchor,
            distance: calculateDistance(to: anchor),
            isVisible: true,
            arInfo: ARPOIInfo(from: poi)
        )
        
        // Добавление в список обнаруженных POI
        if !detectedPOIs.contains(where: { $0.id == poi.id }) {
            detectedPOIs.append(arPOI)
        }
        
        // Создание AR узла для POI
        createPOINode(for: arPOI)
        
        // Обновление состояния сессии
        sessionState.detectedPOIs = detectedPOIs
        
        // Логирование события
        logAREvent(AREvent(
            type: .poiDetected,
            timestamp: Date(),
            poiId: poi.id,
            routeId: nil,
            questId: nil,
            metadata: ["distance": String(arPOI.distance)]
        ))
        
        // Интеграция с геймификацией
        Task {
            await handleARPOIDetection(poi)
        }
    }
    
    private func createPOINode(for arPOI: ARPOI) {
        let node = SCNNode()
        
        // Создание геометрии для POI
        let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        geometry.firstMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.3)
        
        node.geometry = geometry
        node.name = arPOI.id
        
        // Добавление текста с названием POI
        let textGeometry = SCNText(string: arPOI.poi.title, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.05)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(0, 0.1, 0)
        node.addChildNode(textNode)
        
        // Добавление в сцену
        arSceneView?.scene.rootNode.addChildNode(node)
        poiNodes[arPOI.id] = node
    }
    
    private func calculateDistance(to anchor: ARAnchor) -> Float {
        guard let cameraTransform = arSession?.currentFrame?.camera.transform else {
            return 0
        }
        
        let anchorPosition = anchor.transform.columns.3
        let cameraPosition = cameraTransform.columns.3
        
        let distance = sqrt(
            pow(anchorPosition.x - cameraPosition.x, 2) +
            pow(anchorPosition.y - cameraPosition.y, 2) +
            pow(anchorPosition.z - cameraPosition.z, 2)
        )
        
        return distance
    }
    
    // MARK: - AR Navigation
    func startARNavigation(route: Route) {
        Task {
            do {
                let pois = try await firestoreService.fetchPOIList()
                let routePOIs = pois.filter { route.stops.contains($0.id) }
                
                let waypoints = routePOIs.enumerated().map { index, poi in
                    ARWaypoint(
                        poi: poi,
                        anchor: ARAnchor(),
                        distance: 0,
                        direction: 0,
                        isCompleted: false
                    )
                }
                
                let arRoute = ARRoute(
                    route: route,
                    waypoints: waypoints,
                    currentWaypointIndex: 0,
                    distanceToNext: 0,
                    estimatedTime: TimeInterval(route.durationMinutes * 60)
                )
                
                await MainActor.run {
                    self.currentRoute = arRoute
                    self.currentARMode = .navigation
                    self.navigationState.isActive = true
                    self.navigationState.currentRoute = arRoute
                    self.uiState.showNavigationElements = true
                    self.uiState.showPOICards = false
                }
                
                // Логирование события
                logAREvent(AREvent(
                    type: .navigationStarted,
                    timestamp: Date(),
                    poiId: nil,
                    routeId: route.id,
                    questId: nil,
                    metadata: ["waypoints": String(waypoints.count)]
                ))
                
            } catch {
                await MainActor.run {
                    self.error = "Ошибка загрузки маршрута: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateARNavigation() {
        guard let route = currentRoute else { return }
        
        // Обновление навигационных элементов
        updateNavigationArrows()
        updateDistanceIndicators()
        updateTurnByTurnInstructions()
    }
    
    private func updateNavigationArrows() {
        // Создание стрелок навигации
        guard let route = currentRoute else { return }
        
        // Очистка старых навигационных узлов
        navigationNodes.values.forEach { $0.removeFromParentNode() }
        navigationNodes.removeAll()
        
        // Создание новых стрелок
        for (index, waypoint) in route.waypoints.enumerated() {
            if index >= route.currentWaypointIndex {
                let arrowNode = createNavigationArrow(for: waypoint)
                arSceneView?.scene.rootNode.addChildNode(arrowNode)
                navigationNodes["arrow_\(index)"] = arrowNode
            }
        }
    }
    
    private func createNavigationArrow(for waypoint: ARWaypoint) -> SCNNode {
        let arrowNode = SCNNode()
        
        // Создание геометрии стрелки
        let arrowGeometry = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.2)
        arrowGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        arrowGeometry.firstMaterial?.emission.contents = UIColor.blue.withAlphaComponent(0.5)
        
        arrowNode.geometry = arrowGeometry
        arrowNode.position = SCNVector3(0, 0.5, -2) // 2 метра впереди, 0.5 метра вверх
        
        return arrowNode
    }
    
    private func updateDistanceIndicators() {
        // Обновление индикаторов расстояния
    }
    
    private func updateTurnByTurnInstructions() {
        // Обновление пошаговых инструкций
    }
    
    // MARK: - AR Audio
    func playSpatialAudio(for poi: POI) {
        guard let audioURL = poi.audio.first else { return }
        
        // Создание пространственного аудио узла
        let audioNode = createSpatialAudioNode(url: audioURL)
        audioNode.position = SCNVector3(0, 0, -2) // 2 метра впереди
        
        // Добавление в AR сцену
        arSceneView?.scene.rootNode.addChildNode(audioNode)
        audioNodes[poi.id] = audioNode
        
        // Интеграция с существующим аудио сервисом
        audioService.loadAudio(
            from: URL(string: audioURL)!,
            title: "AR: \(poi.title)",
            poiId: poi.id
        )
        
        // Обновление состояния аудио
        audioState.isPlaying = true
        audioState.currentPOI = poi
        audioState.audioURL = audioURL
        audioState.isSpatial = true
        audioState.position = SCNVector3(0, 0, -2)
        
        // Логирование события
        logAREvent(AREvent(
            type: .audioPlayed,
            timestamp: Date(),
            poiId: poi.id,
            routeId: nil,
            questId: nil,
            metadata: ["audio_url": audioURL]
        ))
    }
    
    private func createSpatialAudioNode(url: String) -> SCNNode {
        let audioNode = SCNNode()
        
        // Создание источника звука
        let audioSource = SCNAudioSource(url: URL(string: url)!)!
        audioSource.volume = 1.0
        audioSource.isPositional = true
        audioSource.shouldStream = true
        
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        audioNode.addAudioPlayer(audioPlayer)
        
        return audioNode
    }
    
    // MARK: - AR Quests and Gamification
    private func handleARPOIDetection(_ poi: POI) async {
        // Обновление AR статистики
        await updateARStatistics()
        
        // Проверка AR-квестов
        await checkARQuests(for: poi)
        
        // Проверка AR-достижений
        await checkARAchievements()
    }
    
    func handleARPhotoCapture(_ poi: POI) async {
        // Обработка фотографирования в AR
        await gamificationService.handleARPhotoCapture(poi.id)
        
        // Логирование события
        logAREvent(AREvent(
            type: .photoTaken,
            timestamp: Date(),
            poiId: poi.id,
            routeId: nil,
            questId: nil,
            metadata: [:]
        ))
    }
    
    func handleARQuestCompletion(_ questId: String) async {
        // Завершение AR-квеста
        await gamificationService.handleARQuestCompletion(questId)
        
        // Логирование события
        logAREvent(AREvent(
            type: .questCompleted,
            timestamp: Date(),
            poiId: nil,
            routeId: nil,
            questId: questId,
            metadata: [:]
        ))
    }
    
    private func checkARQuests(for poi: POI) async {
        // Проверка AR-квестов для данного POI
    }
    
    private func checkARAchievements() async {
        // Проверка AR-достижений
    }
    
    private func updateARQuests() {
        // Обновление активных AR-квестов
    }
    
    // MARK: - Performance and Statistics
    private func updateARStatistics() {
        // Обновление AR статистики
    }
    
    private func logAREvent(_ event: AREvent) {
        performanceMonitor.logAREvent(event)
    }
    
    // MARK: - Scene Management
    private func clearARScene() {
        // Очистка всех AR узлов
        poiNodes.values.forEach { $0.removeFromParentNode() }
        navigationNodes.values.forEach { $0.removeFromParentNode() }
        audioNodes.values.forEach { $0.removeFromParentNode() }
        
        poiNodes.removeAll()
        navigationNodes.removeAll()
        audioNodes.removeAll()
        
        detectedPOIs.removeAll()
        currentRoute = nil
    }
}

// MARK: - ARSessionDelegate & ARSCNViewDelegate
extension ARService: ARSessionDelegate, ARSCNViewDelegate {
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                handleImageAnchor(imageAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                updateImageAnchor(imageAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                removeImageAnchor(imageAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        self.error = error.localizedDescription
        
        // Логирование ошибки
        logAREvent(AREvent(
            type: .error,
            timestamp: Date(),
            poiId: nil,
            routeId: nil,
            questId: nil,
            metadata: ["error": error.localizedDescription]
        ))
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        sessionState.trackingState = camera.trackingState
        
        switch camera.trackingState {
        case .normal:
            // Отслеживание работает нормально
            break
        case .notAvailable:
            error = "Отслеживание AR недоступно"
        case .limited(let reason):
            switch reason {
            case .initializing:
                error = "Инициализация AR..."
            case .excessiveMotion:
                error = "Слишком много движения"
            case .insufficientFeatures:
                error = "Недостаточно особенностей для отслеживания"
            case .relocalizing:
                error = "Перелокализация..."
            @unknown default:
                error = "Ограниченное отслеживание"
            }
        @unknown default:
            error = "Неизвестное состояние отслеживания"
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // AR сессия была прервана
        error = "AR сессия прервана"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // AR сессия возобновлена
        error = nil
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Узел добавлен для якоря
        if let imageAnchor = anchor as? ARImageAnchor {
            handleImageAnchorNode(node, for: imageAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Узел обновлен для якоря
        if let imageAnchor = anchor as? ARImageAnchor {
            updateImageAnchorNode(node, for: imageAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Узел удален для якоря
        if let imageAnchor = anchor as? ARImageAnchor {
            removeImageAnchorNode(node, for: imageAnchor)
        }
    }
    
    // MARK: - Image Anchor Handling
    private func handleImageAnchor(_ imageAnchor: ARImageAnchor) {
        guard let imageName = imageAnchor.referenceImage.name else { return }
        
        // Поиск POI по имени изображения
        Task {
            do {
                let pois = try await firestoreService.fetchPOIList()
                if let poi = pois.first(where: { $0.id == imageName }) {
                    await MainActor.run {
                        self.handlePOIDetection(poi, anchor: imageAnchor)
                    }
                }
            } catch {
                // Fallback на локальные данные
                let pois = localContentService.getPOIs()
                if let poi = pois.first(where: { $0.id == imageName }) {
                    await MainActor.run {
                        self.handlePOIDetection(poi, anchor: imageAnchor)
                    }
                }
            }
        }
    }
    
    private func updateImageAnchor(_ imageAnchor: ARImageAnchor) {
        // Обновление image anchor
        guard let imageName = imageAnchor.referenceImage.name else { return }
        
        // Обновление расстояния и видимости
        if let arPOI = detectedPOIs.first(where: { $0.id == imageName }) {
            let distance = calculateDistance(to: imageAnchor)
            // Обновление AR POI с новым расстоянием
        }
    }
    
    private func removeImageAnchor(_ imageAnchor: ARImageAnchor) {
        // Удаление image anchor
        guard let imageName = imageAnchor.referenceImage.name else { return }
        
        // Удаление POI из списка обнаруженных
        detectedPOIs.removeAll { $0.id == imageName }
        
        // Удаление узла из сцены
        if let node = poiNodes[imageName] {
            node.removeFromParentNode()
            poiNodes.removeValue(forKey: imageName)
        }
    }
    
    private func handleImageAnchorNode(_ node: SCNNode, for imageAnchor: ARImageAnchor) {
        // Обработка узла для image anchor
        guard let imageName = imageAnchor.referenceImage.name else { return }
        
        // Настройка узла
        node.name = imageName
    }
    
    private func updateImageAnchorNode(_ node: SCNNode, for imageAnchor: ARImageAnchor) {
        // Обновление узла для image anchor
    }
    
    private func removeImageAnchorNode(_ node: SCNNode, for imageAnchor: ARImageAnchor) {
        // Удаление узла для image anchor
    }
}

// MARK: - AR Performance Monitor
class ARPerformanceMonitor: ObservableObject {
    @Published var currentMetrics = ARPerformanceMetrics(
        frameRate: 0,
        trackingQuality: .notAvailable,
        batteryUsage: 0,
        memoryUsage: 0,
        sessionDuration: 0,
        detectedAnchors: 0,
        userInteractions: 0,
        timestamp: Date()
    )
    
    private var events: [AREvent] = []
    private var isMonitoring = false
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    func logAREvent(_ event: AREvent) {
        events.append(event)
    }
    
    func getPerformanceReport() -> ARPerformanceReport {
        return ARPerformanceReport(
            totalEvents: events.count,
            sessionDuration: currentMetrics.sessionDuration,
            averageFrameRate: currentMetrics.frameRate,
            events: events
        )
    }
}

struct ARPerformanceReport {
    let totalEvents: Int
    let sessionDuration: TimeInterval
    let averageFrameRate: Double
    let events: [AREvent]
}