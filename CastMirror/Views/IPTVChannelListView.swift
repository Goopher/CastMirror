import SwiftUI

struct IPTVChannelListView: View {
    @EnvironmentObject var iptvController: IPTVController
    @EnvironmentObject var castSession: CastSessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search channels", text: $iptvController.searchText)
                    .disableAutocorrection(true)
                if !iptvController.searchText.isEmpty {
                    Button {
                        iptvController.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if iptvController.filteredChannels.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tv.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Channels Found")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
            } else {
                List(iptvController.filteredChannels) { channel in
                    Button {
                        iptvController.playChannel(channel, castSession: castSession)
                    } label: {
                        HStack(spacing: 12) {
                            channelIcon(for: channel)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.displayName)
                                    .font(.body)
                                    .lineLimit(1)
                                if let num = channel.num {
                                    Text("Ch. \(num)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .tint(.primary)
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func channelIcon(for channel: XtreamChannel) -> some View {
        if let iconURL = channel.streamIcon,
           !iconURL.isEmpty,
           let url = URL(string: iconURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                default:
                    defaultIcon
                }
            }
        } else {
            defaultIcon
        }
    }

    private var defaultIcon: some View {
        Image(systemName: "tv")
            .font(.title3)
            .foregroundStyle(.blue)
            .frame(width: 36, height: 36)
    }
}
