import SwiftUI

struct MirrorControlView: View {
    @EnvironmentObject var castSession: CastSessionManager
    @EnvironmentObject var mirrorController: MirrorController

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Mirror button
            Button {
                Task {
                    if mirrorController.state.isActive {
                        await mirrorController.stopMirroring(castSession: castSession)
                    } else {
                        await mirrorController.startMirroring(castSession: castSession)
                    }
                }
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: mirrorController.state.isActive ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 72))
                    Text(mirrorController.state.isActive ? "Stop Mirroring" : "Start Mirroring")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .buttonStyle(.borderedProminent)
            .tint(mirrorController.state.isActive ? .red : .blue)
            .padding(.horizontal, 40)

            // FPS indicator
            if mirrorController.state.isActive {
                HStack {
                    Image(systemName: "speedometer")
                    Text("\(mirrorController.fps) FPS")
                        .monospacedDigit()
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Quality & resolution controls
            VStack(alignment: .leading, spacing: 20) {
                // JPEG Quality
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("JPEG Quality")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(mirrorController.jpegQuality * 100))%")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $mirrorController.jpegQuality, in: 0.1...1.0, step: 0.05)
                }

                // Fix #4: Resolution scale slider exposed in UI.
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Resolution Scale")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(mirrorController.scaleFactor * 100))%")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $mirrorController.scaleFactor, in: 0.25...1.0, step: 0.05)
                }

                Text("Lower quality / scale = less latency, less bandwidth")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
