import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "rectangle.split.3x1.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Welcome to Desktop Namer")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Name your virtual desktops and see them at a glance.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                OnboardingStep(
                    icon: "menubar.rectangle",
                    title: "Menu Bar",
                    description: "Desktop Namer lives in your menu bar. Click it to see all your desktops."
                )

                OnboardingStep(
                    icon: "pencil",
                    title: "Rename Desktops",
                    description: "Click the pencil icon next to any desktop to give it a custom name."
                )

                OnboardingStep(
                    icon: "keyboard",
                    title: "Keyboard Shortcuts",
                    description: "Use Ctrl+1–9 to switch desktops. Enable \"Switch to Desktop N\" in System Settings > Keyboard > Keyboard Shortcuts > Mission Control."
                )

                OnboardingStep(
                    icon: "lock.shield",
                    title: "Accessibility Access",
                    description: "For keyboard shortcuts to work, grant Accessibility access in System Settings > Privacy & Security > Accessibility."
                )
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)

            Spacer()

            // Button
            Button {
                markOnboardingComplete()
                onComplete()
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(width: 400, height: 520)
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "com.desktopnamer.onboardingComplete")
    }

    static var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: "com.desktopnamer.onboardingComplete")
    }
}

struct OnboardingStep: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
