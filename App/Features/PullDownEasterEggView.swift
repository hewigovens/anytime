import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

struct PullDownEasterEggView: View {
    let monitor: PullDownMonitor
    @State private var latchedPullDistance: CGFloat = 0
    @State private var releaseTask: Task<Void, Never>?
    @State private var quipTask: Task<Void, Never>?
    @State private var currentQuip = PullDownQuipGenerator.randomFallback()
    @State private var didTriggerCurrentPull = false
    @State private var quipTilt: Double = 0

    private let panelRevealOffset: CGFloat = 200
    private let textRevealOffset: CGFloat = 104
    private let textRevealRange: CGFloat = 72
    private let latchThreshold: CGFloat = 122

    private var pullDistance: CGFloat {
        monitor.pullDistance
    }

    private var effectivePullDistance: CGFloat {
        max(pullDistance, latchedPullDistance)
    }

    private var revealProgress: CGFloat {
        max(0, min(1, (effectivePullDistance - textRevealOffset) / textRevealRange))
    }

    private var panelHeight: CGFloat {
        max(0, min(280, effectivePullDistance - panelRevealOffset))
    }

    var body: some View {
        GeometryReader { proxy in
            if panelHeight > 1 {
                VStack {
                    Spacer(minLength: proxy.safeAreaInsets.top + 18)

                    Label(currentQuip, systemImage: "sparkles")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.searchFieldSurface.opacity(0.92))
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(AppTheme.searchFieldStroke, lineWidth: 1)
                        }
                        .rotationEffect(.degrees(quipTilt))
                        .opacity(revealProgress)

                    Spacer(minLength: 22)
                }
                .frame(maxWidth: .infinity)
                .frame(height: panelHeight)
                .background(
                    LinearGradient(
                        colors: [
                            AppTheme.panelTop,
                            AppTheme.panelBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppTheme.panelDivider)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .accessibilityHidden(revealProgress < 0.95)
            }
        }
        .onChange(of: pullDistance) { _, newValue in
            if newValue > latchThreshold {
                releaseTask?.cancel()
                latchedPullDistance = max(latchedPullDistance, newValue)
                if didTriggerCurrentPull == false {
                    didTriggerCurrentPull = true
                    refreshQuip()
                }
            } else if newValue <= 1, latchedPullDistance > 0 {
                releaseTask?.cancel()
                quipTask?.cancel()
                didTriggerCurrentPull = false
                releaseTask = Task {
                    try? await Task.sleep(for: .milliseconds(650))
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.2)) {
                            latchedPullDistance = 0
                        }
                    }
                }
            }
        }
    }

    private func refreshQuip() {
        currentQuip = PullDownQuipGenerator.randomFallback()
        quipTilt = PullDownQuipGenerator.randomTilt()
        quipTask?.cancel()
        quipTask = Task {
            guard let generatedQuip = await PullDownQuipGenerator.generate() else {
                return
            }

            guard Task.isCancelled == false else {
                return
            }

            await MainActor.run {
                currentQuip = generatedQuip
                quipTilt = PullDownQuipGenerator.randomTilt()
            }
        }
    }
}

private enum PullDownQuipGenerator {
    private static let fallbackQuips = [
        "Time goblin approved.",
        "You found the secret clock.",
        "Timezone wizard detected.",
        "A tiny break in spacetime.",
        "Certified procrastination window.",
        "UTC is judging you.",
        "You pulled. Time answered.",
        "Minutes were harmed here."
    ]

    static func randomFallback() -> String {
        fallbackQuips.randomElement() ?? "Time goblin approved."
    }

    static func randomTilt() -> Double {
        Double.random(in: -2.5 ... 2.5)
    }

    static func generate() async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await generateWithFoundationModel()
        }
        #endif

        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static func generateWithFoundationModel() async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable, model.supportsLocale() else {
            return nil
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            Write one playful short line for a world clock app easter egg.
            Keep it under six words.
            Keep it light and a little weird.
            Return plain text only.
            """
        )

        do {
            let response = try await session.respond(
                to: "Generate one line.",
                options: GenerationOptions(
                    temperature: 1.2,
                    maximumResponseTokens: 24
                )
            )

            let cleaned = response.content
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard cleaned.isEmpty == false, cleaned.split(separator: " ").count <= 6 else {
                return nil
            }

            return cleaned
        } catch {
            return nil
        }
    }
    #endif
}
