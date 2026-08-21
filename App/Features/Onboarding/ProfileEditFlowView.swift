import Core
import Foundation
import SwiftUI

struct ProfileEditFlowView: View {
    private enum Destination: Hashable {
        case profile
    }

    @Binding var draft: OnboardingDraft
    let lastUpdatedAt: Date
    let onSave: (ProfileInput) async -> Bool
    let onSaved: () -> Void

    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            InterestsStepView(
                selected: interestsBinding,
                context: .profileEdit,
                onNext: { path.append(.profile) }
            )
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .profile:
                    ProfileStepView(
                        draft: $draft,
                        mode: .edit(lastUpdatedAt: lastUpdatedAt),
                        onCreate: onSave,
                        onSaved: onSaved
                    )
                }
            }
        }
    }

    private var interestsBinding: Binding<[String]> {
        Binding(
            get: { draft.interests },
            set: { draft = draft.replacing(interests: $0) }
        )
    }
}
