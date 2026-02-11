import SpriteKit
import SwiftUI

final class GameScene: SKScene {

    private weak var viewModel: GameViewModel?

    private let backgroundLayer = SKNode()
    private let zoneLayer = SKNode()
    private let boatLayer = SKNode()
    private let characterLayer = SKNode()

    private var backgroundNode: SKSpriteNode!
    private var boatNode: SKSpriteNode!

    private var leftBankZone = SKShapeNode()
    private var rightBankZone = SKShapeNode()
    private var boatZone = SKShapeNode()

    private var characterNodes: [UUID: SKSpriteNode] = [:]
    private var nodeIdMap: [String: UUID] = [:]

    private var draggingId: UUID?
    private var draggingStartPosition: CGPoint = .zero
    private var isDragging: Bool = false

    private var lastBoatSide: BankSide?
    private var isBoatSailing: Bool = false

    var debugShowZones: Bool = false {
        didSet { updateZoneVisibility() }
    }

    private let texturesFaceRightByDefault: Bool = true
    private let characterTargetHeight: CGFloat = 110

    private let boatWidthRatio: CGFloat = 0.22
    private let bottomPadding: CGFloat = 40
    private let boatYFromBottom: CGFloat = 58
    private let boatDeckHeightRatio: CGFloat = 0.33
    private let boatSlotXRatio: CGFloat = 0.17

    private let sidePadding: CGFloat = 40
    private let boatSailDuration: TimeInterval = 1.0
    private let characterMoveDuration: TimeInterval = 0.28
    private let dragReturnDuration: TimeInterval = 0.20

    private let minDistance: CGFloat = 90

    private let bankSafeExtra: CGFloat = 28
    private let bankTopSafeExtra: CGFloat = 120
    private let bankBottomExtra: CGFloat = 110

    private let rowsTargetCount: Int = 4
    private let rowJitter: CGFloat = 10

    private let zPositions = ZPositions()

    struct ZPositions {
        let background: CGFloat = 0
        let boat: CGFloat = 10
        let characterOnIsland: CGFloat = 20
        let characterInBoatSlot0: CGFloat = 21
        let characterInBoatSlot1: CGFloat = 22
        let characterDragging: CGFloat = 1000
        let zones: CGFloat = 100
    }

    private var cachedLeftBankPos: [UUID: CGPoint] = [:]
    private var cachedRightBankPos: [UUID: CGPoint] = [:]
    private var cachedLevelIndex: Int?

    private var boatSlotById: [UUID: Int] = [:]

    private var safeInsets: UIEdgeInsets = .zero
    private var hudTopInset: CGFloat = 0
    private var hudBottomInset: CGFloat = 0

    func updateSafeArea(_ insets: UIEdgeInsets) {
        safeInsets = insets
        invalidateCachedBankPositions()
    }

    func updateHUDInsets(top: CGFloat, bottom: CGFloat) {
        hudTopInset = max(0, top)
        hudBottomInset = max(0, bottom)
        invalidateCachedBankPositions()
    }

    private func invalidateCachedBankPositions() {
        cachedLeftBankPos.removeAll()
        cachedRightBankPos.removeAll()
    }

    init(size: CGSize, viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(size: size)

        scaleMode = .resizeFill
        backgroundColor = .clear

        setupSceneGraph()
        setupBackground()
        setupBoat()
        setupZones()
        setupCharacters()

        lastBoatSide = viewModel.state.boatSide
        cachedLevelIndex = viewModel.level.index

        applyState(viewModel.state, level: viewModel.level, animated: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if isBoatSailing { layoutBoatZone() }
    }

    private func setupSceneGraph() {
        addChild(backgroundLayer)
        addChild(zoneLayer)
        addChild(boatLayer)
        addChild(characterLayer)

        backgroundLayer.zPosition = zPositions.background
        boatLayer.zPosition = zPositions.boat
        characterLayer.zPosition = zPositions.characterOnIsland
        zoneLayer.zPosition = zPositions.zones
    }

    private func setupBackground() {
        let texture = SKTexture(imageNamed: "gameBackground")
        backgroundNode = SKSpriteNode(texture: texture)
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundNode.zPosition = zPositions.background
        backgroundLayer.addChild(backgroundNode)
    }

    private func setupBoat() {
        let texture = SKTexture(imageNamed: "boatSprite")
        boatNode = SKSpriteNode(texture: texture)

        if texture.size().width == 0 {
            boatNode = SKSpriteNode(color: .systemBlue, size: CGSize(width: 240, height: 70))
        }

        boatNode.name = "boat"
        boatNode.zPosition = zPositions.boat
        boatNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        boatLayer.addChild(boatNode)
    }

    private func setupZones() {
        configureZone(leftBankZone, name: "zone_left")
        configureZone(rightBankZone, name: "zone_right")
        configureZone(boatZone, name: "zone_boat")

        zoneLayer.addChild(leftBankZone)
        zoneLayer.addChild(rightBankZone)
        zoneLayer.addChild(boatZone)

        updateZoneVisibility()
    }

    private func configureZone(_ node: SKShapeNode, name: String) {
        node.name = name
        node.fillColor = .clear
        node.strokeColor = .white.withAlphaComponent(0.35)
        node.lineWidth = 2
        node.alpha = 0.001
        node.zPosition = zPositions.zones
    }

    private func updateZoneVisibility() {
        let a: CGFloat = debugShowZones ? 1.0 : 0.001
        leftBankZone.alpha = a
        rightBankZone.alpha = a
        boatZone.alpha = a
    }

    private func setupCharacters() {
        guard let vm = viewModel else { return }

        for obj in vm.level.objects {
            if characterNodes[obj.id] != nil { continue }

            let node = makeCharacterNode(obj)
            let nodeName = "char_\(obj.id.uuidString)"
            node.name = nodeName

            nodeIdMap[nodeName] = obj.id
            characterNodes[obj.id] = node
            characterLayer.addChild(node)

            node.zPosition = zPositions.characterOnIsland
        }
    }

    private func makeCharacterNode(_ obj: GameObject) -> SKSpriteNode {
        let textureName: String
        switch obj.type {
        case .student: textureName = "character_student"
        case .janitor: textureName = "character_janitor"
        case .gardener: textureName = "character_gardener"
        }

        let texture = SKTexture(imageNamed: textureName)
        let node: SKSpriteNode

        if texture.size().width > 0 {
            node = SKSpriteNode(texture: texture)
        } else {
            node = SKSpriteNode(color: .systemRed, size: CGSize(width: 80, height: 110))
        }

        let texSize = node.texture?.size() ?? CGSize(width: 80, height: 110)
        let safeH = max(texSize.height, 1)
        let scale = characterTargetHeight / safeH
        node.size = CGSize(width: texSize.width * scale, height: texSize.height * scale)

        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.zPosition = zPositions.characterOnIsland
        return node
    }

    func sync() {
        guard let vm = viewModel else { return }

        if cachedLevelIndex != vm.level.index {
            resetForNewLevel()
            return
        }

        if characterNodes.count != vm.level.objects.count {
            characterLayer.removeAllChildren()
            characterNodes.removeAll()
            nodeIdMap.removeAll()
            invalidateCachedBankPositions()
            boatSlotById.removeAll()
            setupCharacters()
        }

        applyState(vm.state, level: vm.level, animated: true)
    }

    private func applyState(_ state: GameState, level: LevelDefinition, animated: Bool) {
        layoutBackground()
        layoutZones()

        updateBoatSlots(state: state)
        updateParentingForBoatCargo(state: state)

        let boatSideChanged: Bool
        if let lastSide = lastBoatSide {
            boatSideChanged = (lastSide != state.boatSide)
        } else {
            boatSideChanged = true
            lastBoatSide = state.boatSide
        }

        let boatTarget = computeBoatTargetPosition(for: state)

        if animated && boatSideChanged {
            animateBoat(to: boatTarget)
        } else {
            boatNode.removeAction(forKey: "boat_sail")
            boatNode.position = boatTarget
            isBoatSailing = false
        }

        lastBoatSide = state.boatSide
        layoutBoatZone()

        layoutCharacters(for: state, level: level, animated: animated)
        forceFlipAllCharactersOnBanks(state: state)
    }

    private func layoutBackground() {
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.size = size
    }

    private func layoutZones() {
        let w = size.width
        let h = size.height

        leftBankZone.path = CGPath(rect: CGRect(x: 0, y: 0, width: w * 0.35, height: h), transform: nil)
        rightBankZone.path = CGPath(rect: CGRect(x: w * 0.65, y: 0, width: w * 0.35, height: h), transform: nil)
    }

    private func computeBoatTargetPosition(for state: GameState) -> CGPoint {
        let targetWidth = size.width * boatWidthRatio
        let texSize = boatNode.texture?.size() ?? CGSize(width: 520, height: 90)
        let aspect = texSize.height / max(texSize.width, 1)
        boatNode.size = CGSize(width: targetWidth, height: targetWidth * aspect)

        let centerX = size.width * 0.5
        let bw = boatNode.size.width

        let x: CGFloat = (state.boatSide == .left)
            ? (centerX - 0.5 * bw)
            : (centerX + 0.5 * bw)

        let y = bottomPadding + boatYFromBottom
        return CGPoint(x: x, y: y)
    }

    private func layoutBoatZone() {
        let pad: CGFloat = 18
        let rect = boatNode.calculateAccumulatedFrame().insetBy(dx: -pad, dy: -pad)
        boatZone.path = CGPath(rect: rect, transform: nil)
    }

    private func animateBoat(to target: CGPoint) {
        isBoatSailing = true
        boatNode.removeAction(forKey: "boat_sail")

        let move = SKAction.move(to: target, duration: boatSailDuration)
        move.timingMode = .easeInEaseOut

        let done = SKAction.run { [weak self] in
            self?.isBoatSailing = false
            self?.layoutBoatZone()
        }

        boatNode.run(SKAction.sequence([move, done]), withKey: "boat_sail")
    }

    private func updateBoatSlots(state: GameState) {
        for (id, _) in boatSlotById where !state.boatCargo.contains(id) {
            boatSlotById[id] = nil
        }

        var used = Set(boatSlotById.compactMap { $0.value })

        for id in state.boatCargo {
            if boatSlotById[id] != nil { continue }

            if !used.contains(0) {
                boatSlotById[id] = 0
                used.insert(0)
            } else if !used.contains(1) {
                boatSlotById[id] = 1
                used.insert(1)
            } else {
                boatSlotById[id] = 0
            }
        }
    }

    private func updateParentingForBoatCargo(state: GameState) {
        for (id, node) in characterNodes {
            let shouldBeOnBoat = state.boatCargo.contains(id)

            if shouldBeOnBoat {
                let slot = boatSlotById[id] ?? 0

                if node.parent !== boatNode {
                    let worldPos = node.convert(CGPoint.zero, to: self)
                    node.removeFromParent()
                    boatNode.addChild(node)
                    let local = self.convert(worldPos, to: boatNode)
                    node.position = local
                }

                node.zPosition = (slot == 0) ? zPositions.characterInBoatSlot0 : zPositions.characterInBoatSlot1
            } else {
                if node.parent !== characterLayer {
                    let worldPos = node.convert(CGPoint.zero, to: self)
                    node.removeFromParent()
                    characterLayer.addChild(node)
                    let local = self.convert(worldPos, to: characterLayer)
                    node.position = local
                }

                node.zPosition = zPositions.characterOnIsland
                let bank = state.left.contains(id) ? BankSide.left : BankSide.right
                ensureFacingOnIsland(node: node, bank: bank)
            }
        }
    }

    private func layoutCharacters(for state: GameState, level: LevelDefinition, animated: Bool) {
        let leftIds = Array(state.left)
        let rightIds = Array(state.right)

        applyBankLayout(ids: leftIds, bank: .left, levelIndex: level.index, allIdsOnBank: leftIds, animated: animated)
        applyBankLayout(ids: rightIds, bank: .right, levelIndex: level.index, allIdsOnBank: rightIds, animated: animated)

        applyBoatLayout(ids: Array(state.boatCargo), animated: animated)
    }

    private func applyBankLayout(ids: [UUID], bank: BankSide, levelIndex: Int, allIdsOnBank: [UUID], animated: Bool) {
        if bank == .left {
            for id in ids { cachedRightBankPos[id] = nil }
        } else {
            for id in ids { cachedLeftBankPos[id] = nil }
        }

        for (index, id) in ids.enumerated() {
            guard let node = characterNodes[id], node.parent === characterLayer else { continue }
            if draggingId == id { continue }

            let target = bankPosition(for: id, bank: bank, levelIndex: levelIndex, indexInBank: index, allIdsOnBank: allIdsOnBank)
            moveNode(node, to: target, animated: animated)

            node.zPosition = zPositions.characterOnIsland
            ensureFacingOnIsland(node: node, bank: bank)
        }
    }

    private func applyBoatLayout(ids: [UUID], animated: Bool) {
        let boatW = boatNode.frame.width
        let boatH = boatNode.frame.height

        let bottomLocalY = -boatH / 2
        let deckLocalY = bottomLocalY + boatH * boatDeckHeightRatio

        let slotPositions: [Int: CGPoint] = [
            0: CGPoint(x: -boatW * boatSlotXRatio, y: deckLocalY),
            1: CGPoint(x:  boatW * boatSlotXRatio, y: deckLocalY)
        ]

        for id in ids {
            guard let node = characterNodes[id], node.parent === boatNode else { continue }
            if draggingId == id { continue }

            let slot = boatSlotById[id] ?? 0
            let targetLocal = slotPositions[slot] ?? CGPoint(x: 0, y: deckLocalY)

            node.zPosition = (slot == 0) ? zPositions.characterInBoatSlot0 : zPositions.characterInBoatSlot1
            moveNode(node, to: targetLocal, animated: animated)
        }
    }

    private func forceFlipAllCharactersOnBanks(state: GameState) {
        for (id, node) in characterNodes {
            if state.boatCargo.contains(id) { continue }
            let bank: BankSide = state.left.contains(id) ? .left : .right
            ensureFacingOnIsland(node: node, bank: bank)
        }
    }

    private func bankPosition(for id: UUID, bank: BankSide, levelIndex: Int, indexInBank: Int, allIdsOnBank: [UUID]) -> CGPoint {
        if bank == .left, let cached = cachedLeftBankPos[id] { return cached }
        if bank == .right, let cached = cachedRightBankPos[id] { return cached }

        let existingPoints: [CGPoint] = {
            if bank == .left {
                return allIdsOnBank.compactMap { cachedLeftBankPos[$0] }
            } else {
                return allIdsOnBank.compactMap { cachedRightBankPos[$0] }
            }
        }()

        let p = generateBankPoint(
            for: id,
            bank: bank,
            levelIndex: levelIndex,
            indexInBank: indexInBank,
            allIdsOnBank: allIdsOnBank,
            existing: existingPoints
        )

        if bank == .left { cachedLeftBankPos[id] = p } else { cachedRightBankPos[id] = p }
        return p
    }

    private func generateBankPoint(
        for id: UUID,
        bank: BankSide,
        levelIndex: Int,
        indexInBank: Int,
        allIdsOnBank: [UUID],
        existing: [CGPoint]
    ) -> CGPoint {

        var rng = SeededRandom(seed: stableSeed(levelIndex: levelIndex, id: id))

        let w = size.width
        let h = size.height

        let leftBankRect = CGRect(x: 0, y: 0, width: w * 0.35, height: h)
        let rightBankRect = CGRect(x: w * 0.65, y: 0, width: w * 0.35, height: h)
        let bankRect = (bank == .left) ? leftBankRect : rightBankRect

        let topCut = max(0, safeInsets.top) + hudTopInset + bankTopSafeExtra
        let bottomCut = max(0, safeInsets.bottom) + hudBottomInset + bankBottomExtra

        var minY = bottomCut + bottomPadding + 30
        var maxY = h - topCut - 8

        if minY >= maxY {
            minY = bottomPadding + 60
            maxY = h - 140
        }

        let safeRect = bankRect.insetBy(dx: max(12, sidePadding + bankSafeExtra * 0.55), dy: 0)

        let cols = 3
        let rows = 3
        let cells = cols * rows

        let layer = indexInBank / cells
        let idxInLayer = indexInBank % cells

        let permutedCell = (idxInLayer * 7) % cells
        let col = permutedCell % cols
        let row = permutedCell / cols

        let usableW = max(1, safeRect.width)
        let usableH = max(1, maxY - minY)

        let colStep = usableW / CGFloat(cols + 1)
        let rowStep = usableH / CGFloat(rows + 1)

        let baseX = safeRect.minX + colStep * CGFloat(col + 1)
        let baseY = minY + rowStep * CGFloat(row + 1)

        let ring = min(layer, 6)
        let angle = CGFloat((layer * 97 + permutedCell * 31) % 360) * (.pi / 180)

        let ringX = CGFloat(ring) * (colStep * 0.38) * cos(angle)
        let ringY = CGFloat(ring) * (rowStep * 0.34) * sin(angle)

        let targetMinDistance = max(minDistance, min(colStep, rowStep) * 0.72)

        var bestPosition = CGPoint(x: baseX, y: baseY)
        var bestScore: CGFloat = -1

        let attempts = 60
        for _ in 0..<attempts {

            var x = baseX + ringX + rng.nextCGFloat(in: -colStep * 0.28...colStep * 0.28)
            var y = baseY + ringY + rng.nextCGFloat(in: -rowStep * 0.30...rowStep * 0.30) + rng.nextCGFloat(in: -rowJitter...rowJitter)

            x = max(safeRect.minX + 10, min(x, safeRect.maxX - 10))
            y = max(minY + 10, min(y, maxY - 10))

            let p = CGPoint(x: x, y: y)

            if existing.isEmpty { return p }

            var minD2: CGFloat = .greatestFiniteMagnitude
            for e in existing {
                let dx = p.x - e.x
                let dy = p.y - e.y
                let d2 = dx * dx + dy * dy
                if d2 < minD2 { minD2 = d2 }
            }

            if minD2 >= targetMinDistance * targetMinDistance { return p }

            if minD2 > bestScore {
                bestScore = minD2
                bestPosition = p
            }
        }

        return bestPosition
    }

    
    private func moveNode(_ node: SKNode, to target: CGPoint, animated: Bool) {
        let duration = animated ? characterMoveDuration : 0

        if duration <= 0.0001 {
            node.removeAction(forKey: "move")
            node.position = target
            return
        }

        let dx = node.position.x - target.x
        let dy = node.position.y - target.y
        if (dx * dx + dy * dy) < 1.0 {
            node.position = target
            return
        }

        node.removeAction(forKey: "move")
        let move = SKAction.move(to: target, duration: duration)
        move.timingMode = .easeInEaseOut
        node.run(move, withKey: "move")
    }

    private func ensureFacingOnIsland(node: SKSpriteNode, bank: BankSide) {
        let shouldFaceRight = (bank == .left)

        let currentScale = node.xScale
        let currentAbsScale = abs(currentScale)

        let desiredXScale: CGFloat
        if texturesFaceRightByDefault {
            desiredXScale = shouldFaceRight ? currentAbsScale : -currentAbsScale
        } else {
            desiredXScale = shouldFaceRight ? -currentAbsScale : currentAbsScale
        }

        if (currentScale >= 0 && desiredXScale < 0) || (currentScale < 0 && desiredXScale >= 0) {
            node.xScale = desiredXScale
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBoatSailing else { return }
        guard viewModel != nil else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        if let charNode = tappedNodes.first(where: { ($0.name ?? "").hasPrefix("char_") }) as? SKSpriteNode,
           let nodeName = charNode.name,
           let id = nodeIdMap[nodeName] {

            draggingId = id
            isDragging = true

            if charNode.parent === boatNode {
                let worldPos = boatNode.convert(charNode.position, to: self)
                draggingStartPosition = worldPos
                charNode.zPosition = zPositions.characterDragging
            } else {
                draggingStartPosition = charNode.position
                charNode.zPosition = zPositions.characterDragging
            }

            charNode.run(SKAction.scale(to: 1.05, duration: 0.08))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard isDragging, let id = draggingId else { return }
        guard let node = characterNodes[id] else { return }

        let scenePoint = touch.location(in: self)

        if node.parent === boatNode {
            let local = convert(scenePoint, to: boatNode)
            node.position = local
        } else {
            let local = convert(scenePoint, to: characterLayer)
            node.position = local
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBoatSailing else { return }
        guard let vm = viewModel else { return }
        guard let touch = touches.first else { return }

        let scenePoint = touch.location(in: self)

        if isDragging, let id = draggingId, let node = characterNodes[id] {
            isDragging = false
            draggingId = nil

            node.run(SKAction.scale(to: 1.0, duration: 0.08))

            let state = vm.state
            let sourceIsBoat = state.boatCargo.contains(id)
            let target = dropTarget(scenePoint)

            if sourceIsBoat {
                switch target {
                case .leftBank where state.boatSide == .left:
                    node.zPosition = zPositions.characterOnIsland
                    vm.unloadFromBoat(objectId: id)
                    return

                case .rightBank where state.boatSide == .right:
                    node.zPosition = zPositions.characterOnIsland
                    vm.unloadFromBoat(objectId: id)
                    return

                default:
                    let slot = boatSlotById[id] ?? 0
                    node.zPosition = (slot == 0) ? zPositions.characterInBoatSlot0 : zPositions.characterInBoatSlot1
                    returnDraggedNode(node, fallbackId: id)
                    return
                }
            } else {
                if target == .boat {
                    let bankIds = state.bank(state.boatSide)

                    if bankIds.contains(id) {
                        if state.boatCargo.count >= vm.level.boatCapacity {
                            node.zPosition = zPositions.characterOnIsland
                            returnDraggedNode(node, fallbackId: id)
                            return
                        }

                        vm.loadToBoat(objectId: id)
                        return
                    }
                }

                node.zPosition = zPositions.characterOnIsland
                returnDraggedNode(node, fallbackId: id)
                return
            }
        }

        if boatContains(scenePoint: scenePoint) {
            vm.sail()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDragging, let id = draggingId, let node = characterNodes[id] {
            isDragging = false
            draggingId = nil

            if let viewModel = viewModel {
                let state = viewModel.state
                if state.boatCargo.contains(id) {
                    let slot = boatSlotById[id] ?? 0
                    node.zPosition = (slot == 0) ? zPositions.characterInBoatSlot0 : zPositions.characterInBoatSlot1
                } else {
                    node.zPosition = zPositions.characterOnIsland
                }
            } else {
                node.zPosition = zPositions.characterOnIsland
            }

            node.run(SKAction.scale(to: 1.0, duration: 0.08))
            returnDraggedNode(node, fallbackId: id)
        }
    }

    private func returnDraggedNode(_ node: SKSpriteNode, fallbackId: UUID) {
        node.removeAction(forKey: "drag_return")

        if node.parent === boatNode {
            let boatW = boatNode.frame.width
            let boatH = boatNode.frame.height
            let bottomLocalY = -boatH / 2
            let deckLocalY = bottomLocalY + boatH * boatDeckHeightRatio

            let slot = boatSlotById[fallbackId] ?? 0
            let targetX = (slot == 0) ? -boatW * boatSlotXRatio : boatW * boatSlotXRatio
            let targetLocal = CGPoint(x: targetX, y: deckLocalY)

            let move = SKAction.move(to: targetLocal, duration: dragReturnDuration)
            move.timingMode = .easeInEaseOut
            node.run(move, withKey: "drag_return")
        } else {
            let move = SKAction.move(to: draggingStartPosition, duration: dragReturnDuration)
            move.timingMode = .easeInEaseOut
            node.run(move, withKey: "drag_return")
        }
    }

    private enum DropTarget {
        case leftBank
        case rightBank
        case boat
        case water
    }

    private func dropTarget(_ p: CGPoint) -> DropTarget {
        if boatContains(scenePoint: p) { return .boat }
        if leftBankContains(scenePoint: p) { return .leftBank }
        if rightBankContains(scenePoint: p) { return .rightBank }
        return .water
    }

    private func leftBankContains(scenePoint p: CGPoint) -> Bool {
        let pt = convert(p, to: zoneLayer)
        return leftBankZone.contains(pt)
    }

    private func rightBankContains(scenePoint p: CGPoint) -> Bool {
        let pt = convert(p, to: zoneLayer)
        return rightBankZone.contains(pt)
    }

    private func boatContains(scenePoint p: CGPoint) -> Bool {
        let pt = convert(p, to: zoneLayer)
        return boatZone.contains(pt)
    }

    func resetForNewLevel() {
        guard let vm = viewModel else { return }

        boatNode.removeAllActions()

        for (_, node) in characterNodes {
            node.removeAllActions()
            node.removeAction(forKey: "move")
            node.removeAction(forKey: "drag_return")
        }

        invalidateCachedBankPositions()
        boatSlotById.removeAll()

        isDragging = false
        draggingId = nil
        draggingStartPosition = .zero

        lastBoatSide = nil
        isBoatSailing = false

        characterLayer.removeAllChildren()
        characterNodes.removeAll()
        nodeIdMap.removeAll()

        setupCharacters()

        cachedLevelIndex = vm.level.index
        applyState(vm.state, level: vm.level, animated: false)
    }

    private func stableSeed(levelIndex: Int, id: UUID) -> UInt64 {
        var h: UInt64 = 1469598103934665603
        h = fnvMix(h, UInt64(levelIndex))

        var u = id.uuid
        withUnsafeBytes(of: &u) { raw in
            for b in raw { h = fnvMixByte(h, b) }
        }
        return h
    }

    private func fnvMix(_ h: UInt64, _ v: UInt64) -> UInt64 {
        var x = h
        var vv = v
        for _ in 0..<8 {
            x = fnvMixByte(x, UInt8(vv & 0xFF))
            vv >>= 8
        }
        return x
    }

    private func fnvMixByte(_ h: UInt64, _ b: UInt8) -> UInt64 {
        let prime: UInt64 = 1099511628211
        var x = h
        x ^= UInt64(b)
        x = x &* prime
        return x
    }
}

private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func nextDouble() -> Double {
        let v = nextUInt64() >> 11
        return Double(v) / Double(1 << 53)
    }

    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let t = CGFloat(nextDouble())
        return range.lowerBound + (range.upperBound - range.lowerBound) * t
    }
}
