import SwiftUI

struct IPTVLoginView: View {
    @EnvironmentObject var iptvController: IPTVController

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "tv.and.mediabox")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Xtream IPTV")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your Xtream Codes credentials to browse and cast live TV channels.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                TextField("Server URL", text: $iptvController.credentials.server)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)

                TextField("Username", text: $iptvController.credentials.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $iptvController.credentials.password)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)

            Button {
                Task { await iptvController.login() }
            } label: {
                Text("Connect")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            if case .error(let message) = iptvController.viewState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}
