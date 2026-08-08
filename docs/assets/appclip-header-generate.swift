import CoreGraphics
import Foundation
import ImageIO
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// App Clip 헤더 이미지 — POSTECH 메인 컬러 앵커 + 스테인글라스 성당 창 느낌.
// 중앙에는 "겹"(두 카드가 겹치는) 형상을 레드 글라스로.

let width = 1800
let height = 1200
let cx: CGFloat = CGFloat(width) / 2
let cy: CGFloat = CGFloat(height) / 2

struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat

    init(_ hex: UInt32) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
    }

    init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.r = r; self.g = g; self.b = b
    }

    func lightened(_ amount: CGFloat) -> RGB {
        RGB(r: r + (1 - r) * amount, g: g + (1 - g) * amount, b: b + (1 - b) * amount)
    }

    func darkened(_ amount: CGFloat) -> RGB {
        RGB(r: r * (1 - amount), g: g * (1 - amount), b: b * (1 - amount))
    }

    func cgColor(_ alpha: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

// POSTECH 팔레트 + 성당 스테인글라스 느낌을 위한 보조 톤(레드·골드 계열 안에서만 확장).
let palette: [RGB] = [
    RGB(0xA6_19_55), // POSTECH Red — 메인
    RGB(0x7A_10_42), // 딥 레드
    RGB(0xF6_A7_00), // Orange
    RGB(0xDA_BA_65), // Gold
    RGB(0x74_D6_E4), // Mint
    RGB(0x2F_6F_74), // Deep Teal
    RGB(0x8A_23_40), // 로즈
    RGB(0xC0_3B_6E), // 마젠타 로즈
]

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
var rng = SeededRNG(seed: 20260808)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("context 생성 실패")
}

// 1. 리드(lead came) 베이스 — 짙은 자단(紫丹) 블랙
ctx.setFillColor(RGB(0x14_0A_10).cgColor())
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

func wedgePath(a0: CGFloat, a1: CGFloat, r0: CGFloat, r1: CGFloat, segments: Int = 6) -> CGMutablePath {
    let path = CGMutablePath()
    for i in 0...segments {
        let a = a0 + (a1 - a0) * CGFloat(i) / CGFloat(segments)
        let p = CGPoint(x: cx + cos(a) * r1, y: cy + sin(a) * r1)
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    for i in 0...segments {
        let a = a1 - (a1 - a0) * CGFloat(i) / CGFloat(segments)
        let p = CGPoint(x: cx + cos(a) * r0, y: cy + sin(a) * r0)
        path.addLine(to: p)
    }
    path.closeSubpath()
    return path
}

// 2. 로즈 윈도우 판 — 링 × 쐐기, 중심 원(반지름 260)은 비워 엠블럼 자리로.
let innerR: CGFloat = 260
let outerR: CGFloat = 1120
let rings = 6
for ring in 0..<rings {
    let r0 = innerR + (outerR - innerR) * CGFloat(ring) / CGFloat(rings)
    let r1 = innerR + (outerR - innerR) * CGFloat(ring + 1) / CGFloat(rings)
    let wedgeCount = 12 + ring * 4
    for w in 0..<wedgeCount {
        let jitter = (CGFloat.random(in: -0.02...0.02, using: &rng))
        let a0 = (CGFloat(w) / CGFloat(wedgeCount)) * .pi * 2 + jitter
        let a1 = (CGFloat(w + 1) / CGFloat(wedgeCount)) * .pi * 2 + jitter
        let rj0 = r0 + CGFloat.random(in: -18...18, using: &rng)
        let rj1 = r1 + CGFloat.random(in: -18...18, using: &rng)

        let base = palette.randomElement(using: &rng) ?? palette[0]
        let path = wedgePath(a0: a0, a1: a1, r0: max(rj0, innerR - 30), r1: rj1)

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()

        let midA = (a0 + a1) / 2
        let midR = (rj0 + rj1) / 2
        let hx = cx + cos(midA) * midR * 0.55
        let hy = cy + sin(midA) * midR * 0.55
        let colors = [base.lightened(0.4).cgColor(), base.cgColor()] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
            ctx.drawRadialGradient(
                grad, startCenter: CGPoint(x: hx, y: hy), startRadius: 4,
                endCenter: CGPoint(x: hx, y: hy), endRadius: (rj1 - rj0) * 1.3,
                options: .drawsAfterEndLocation
            )
        }
        ctx.restoreGState()

        ctx.addPath(path)
        ctx.setStrokeColor(RGB(0x0A_05_08).cgColor(0.9))
        ctx.setLineWidth(4)
        ctx.strokePath()
    }
}

// 3. 중심에서 뻗어나가는 은은한 빛줄기 (additive)
ctx.saveGState()
ctx.setBlendMode(.plusLighter)
for i in 0..<28 {
    let ang = (CGFloat(i) / 28) * .pi * 2
    let end = CGPoint(x: cx + cos(ang) * outerR, y: cy + sin(ang) * outerR)
    let colors = [
        RGB(r: 1, g: 0.92, b: 0.78).cgColor(0.16),
        RGB(r: 1, g: 0.92, b: 0.78).cgColor(0),
    ] as CFArray
    if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
        ctx.saveGState()
        ctx.setLineWidth(16)
        ctx.setLineCap(.round)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cx, y: cy))
        path.addLine(to: end)
        ctx.addPath(path)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(grad, start: CGPoint(x: cx, y: cy), end: end, options: [])
        ctx.restoreGState()
    }
}
ctx.restoreGState()

// 4. 비네트 — 모서리를 어둡게 눌러 중심에 시선이 모이게.
let vignetteColors = [
    RGB(r: 0, g: 0, b: 0).cgColor(0),
    RGB(r: 0, g: 0, b: 0).cgColor(0.6),
] as CFArray
if let vg = CGGradient(colorsSpace: colorSpace, colors: vignetteColors, locations: [0, 1]) {
    ctx.drawRadialGradient(
        vg, startCenter: CGPoint(x: cx, y: cy), startRadius: outerR * 0.32,
        endCenter: CGPoint(x: cx, y: cy), endRadius: outerR * 1.02,
        options: .drawsAfterEndLocation
    )
}

// 5. 엠블럼 뒤 후광 (골드)
let haloColors = [
    RGB(r: 1, g: 0.9, b: 0.75).cgColor(0.95),
    RGB(0xF6_A7_00).cgColor(0.35),
    RGB(0xF6_A7_00).cgColor(0),
] as CFArray
if let halo = CGGradient(colorsSpace: colorSpace, colors: haloColors, locations: [0, 0.4, 1]) {
    ctx.drawRadialGradient(
        halo, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
        endCenter: CGPoint(x: cx, y: cy), endRadius: 280,
        options: []
    )
}

// 6. 중앙 엠블럼 — 겹치는 두 카드, 레드 글라스.
func roundedRectPath(w: CGFloat, h: CGFloat, r: CGFloat, transform: CGAffineTransform) -> CGPath {
    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    var t = transform
    return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: &t)
}

let cardW: CGFloat = 230
let cardH: CGFloat = 320
let cardR: CGFloat = 30

// 뒷카드 — 어둡고 은은하게
do {
    let transform = CGAffineTransform(rotationAngle: -0.14)
        .concatenating(CGAffineTransform(translationX: cx - 60, y: cy - 35))
    let path = roundedRectPath(w: cardW, h: cardH, r: cardR, transform: transform)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let colors = [
        RGB(0xA6_19_55).lightened(0.15).cgColor(0.55),
        RGB(0xA6_19_55).darkened(0.35).cgColor(0.8),
    ] as CFArray
    if let g = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
        ctx.drawLinearGradient(
            g,
            start: CGPoint(x: cx - 60 - cardW / 2, y: cy - 35 - cardH / 2),
            end: CGPoint(x: cx - 60 + cardW / 2, y: cy - 35 + cardH / 2),
            options: []
        )
    }
    ctx.restoreGState()
    ctx.addPath(path)
    ctx.setStrokeColor(RGB(r: 1, g: 1, b: 1).cgColor(0.4))
    ctx.setLineWidth(4)
    ctx.strokePath()
}

// 앞카드 — 밝고 선명한 레드 글라스 + 스페큘러 하이라이트
do {
    let transform = CGAffineTransform(rotationAngle: 0.11)
        .concatenating(CGAffineTransform(translationX: cx + 58, y: cy + 32))
    let path = roundedRectPath(w: cardW, h: cardH, r: cardR, transform: transform)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let colors = [
        RGB(0xE6_3C_6E).cgColor(0.96),
        RGB(0xA6_19_55).cgColor(0.98),
        RGB(0x78_0F_3C).cgColor(1.0),
    ] as CFArray
    if let g = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.55, 1]) {
        ctx.drawLinearGradient(
            g,
            start: CGPoint(x: cx + 58 - cardW / 2, y: cy + 32 - cardH / 2),
            end: CGPoint(x: cx + 58 + cardW / 2, y: cy + 32 + cardH / 2),
            options: []
        )
    }
    // 스페큘러 하이라이트 스트라이프
    let stripe = CGMutablePath()
    stripe.move(to: CGPoint(x: -cardW / 2, y: cardH / 2))
    stripe.addLine(to: CGPoint(x: -cardW / 2 + 55, y: cardH / 2))
    stripe.addLine(to: CGPoint(x: -cardW / 2 - 25, y: -cardH / 2))
    stripe.addLine(to: CGPoint(x: -cardW / 2 - 80, y: -cardH / 2))
    stripe.closeSubpath()
    ctx.saveGState()
    ctx.concatenate(transform)
    ctx.addPath(stripe)
    ctx.setFillColor(RGB(r: 1, g: 1, b: 1).cgColor(0.4))
    ctx.fillPath()
    ctx.restoreGState()
    ctx.restoreGState()

    ctx.addPath(path)
    ctx.setStrokeColor(RGB(r: 1, g: 1, b: 1).cgColor(0.9))
    ctx.setLineWidth(5)
    ctx.strokePath()
}

// PNG로 저장
guard let image = ctx.makeImage() else { fatalError("이미지 생성 실패") }

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/appclip-header.png"
let url = URL(fileURLWithPath: outputPath) as CFURL

let utType: CFString
if #available(macOS 11.0, *) {
    utType = UTType.png.identifier as CFString
} else {
    utType = "public.png" as CFString
}

guard let dest = CGImageDestinationCreateWithURL(url, utType, 1, nil) else {
    fatalError("destination 생성 실패")
}
CGImageDestinationAddImage(dest, image, nil)
if CGImageDestinationFinalize(dest) {
    print("저장 완료: \(outputPath)")
} else {
    fatalError("저장 실패")
}
