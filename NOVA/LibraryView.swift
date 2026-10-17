
import SwiftUI
import UniformTypeIdentifiers

struct Game: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
}

final class GameLibrary: ObservableObject {
    @Published var games: [Game] = []

    func add(_ url: URL) {
        guard !games.contains(where: { $0.url == url }) else {
            return
        }

        games.append(
            Game(
                name: url.deletingPathExtension().lastPathComponent,
                url: url
            )
        )
    }

    func remove(_ game: Game) {
        games.removeAll { $0.id == game.id }
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibrary()
    @State private var importing = false
    @State private var errorMessage: String?

    private let background = Color(red: 0.035, green: 0.04, blue: 0.075)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ТВОЯ ИГРОВАЯ КОЛЛЕКЦИЯ")
                                .font(.caption.bold())
                                .tracking(2)
                                .foregroundStyle(.cyan)

                            Text("Играй без границ.")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Все твои игры — в одном месте.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        if library.games.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)
                                ],
                                spacing: 14
                            ) {
                                ForEach(library.games) { game in
                                    gameCard(game)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    library.add(url)
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .alert(
            "Ошибка импорта",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text("NOVA")
                    .font(.system(size: 25, weight: .black))
                    .tracking(3)

                Text("GAME LIBRARY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.gray)
            }

            Spacer(minLength: 8)

            Button {
                importing = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.white.opacity(0.04))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.cyan)
                .frame(width: 100, height: 100)
                .background(.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 25))

            Text("Здесь пока пусто")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Импортируй файл игры, чтобы добавить его в библиотеку.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                importing = true
            } label: {
                Label("Импортировать игру", systemImage: "folder")
                    .font(.subheadline.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func gameCard(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 34))
                .foregroundStyle(.cyan)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(game.name)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)

            Button(role: .destructive) {
                library.remove(game)
            } label: {
                Label("Удалить", systemImage: "trash")
                    .font(.caption)
            }
        }
        .padding(12)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var footer: some View {
        HStack {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(.cyan)

            Text("NOVA EMULATOR")
                .tracking(1.5)

            Spacer()

            Text("\(library.games.count) игр")
                .foregroundStyle(.white.opacity(0.6))
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white.opacity(0.75))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.white.opacity(0.04))
    }
}
