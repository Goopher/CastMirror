import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var castSession: CastSessionManager

    var body: some View {
        Group {
            if castSession.discoveredDevices.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tv.and.mediabox")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("Searching for Devices")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Make sure your Chromecast is on the same WiFi network.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                List(castSession.discoveredDevices, id: \.deviceID) { device in
                    Button {
                        castSession.connectToDevice(device)
                    } label: {
                        HStack {
                            Image(systemName: "tv")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(device.friendlyName ?? "Unknown Device")
                                    .font(.body)
                                Text(device.modelName ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
