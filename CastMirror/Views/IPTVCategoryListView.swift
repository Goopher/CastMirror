import SwiftUI

struct IPTVCategoryListView: View {
    @EnvironmentObject var iptvController: IPTVController

    var body: some View {
        Group {
            if iptvController.categories.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("No Categories")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("No live TV categories found on this server.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await iptvController.loadCategories() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            } else {
                List(iptvController.categories) { category in
                    Button {
                        Task { await iptvController.loadChannels(for: category) }
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(category.categoryName)
                                .font(.body)
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
