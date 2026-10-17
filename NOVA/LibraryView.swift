
import SwiftUI
import UniformTypeIdentifiers

struct Game: Identifiable, Codable {
    var id = UUID()
    var name: String
    var url: URL
}

final class GameLibrary: ObservableObject {
    @Published var games: [Game] = []

    func addGame(from url: URL) {
        let name = url.deletingPathExtension().lastPathComponent

        guard !games.contains(where: { $0.url == url }) else {
            return
        }

        games.append(Game(name: name, url: url))
    }

    func removeGame(_ game: Game) {
        games.removeAll { $0.id == game.id }
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibrary()
    @State private var showingImporter = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.035, green: 0.04, blue: 0.07)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            welcomeSection

                            if library.games.isEmpty {
                                emptyLibrary
                            } else {
                                gameGrid
                            }
                        }
                        .padding(20)
                    }

                    footer
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )

                VStack {
                    HStack {
                        Spacer()

                        Text(
                            "\(Int(geometry.size.width)) × \(Int(geometry.size.height))"
                        )
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal, 8)
                .allowsHitTesting(false)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let accessGranted = url.startAccessingSecurityScopedResource()

                    defer {
                        if accessGranted {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    library.addGame(from: url)
                }

            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .alert(
            "Не удалось открыть файл",
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
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("NOVA")
                    .font(.system(size: 25, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.white)

                Text("GAME LIBRARY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button {
                showingImporter = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Добавить игру")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.white.opacity(0.035))
    }

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ТВОЯ ИГРОВАЯ КОЛЛЕКЦИЯ")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(.cyan)

            Text("Играй без границ.")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Добавляй игры и собирай свою библиотеку в одном месте.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyLibrary: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.cyan.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.cyan)
            }

            Text("Здесь пока пусто")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white)

            Text("Импортируй файл игры, чтобы добавить его в библиотеку.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button {
                showingImporter = true
            } label: {
                Label("Импортировать игру", systemImage: "folder.badge.plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 15)
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var gameGrid: some View {
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

    private func gameCard(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.45),
                                Color.purple.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text(game.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Button(role: .destructive) {
                library.removeGame(game)
            } label: {
                Label("Удалить", systemImage: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }

    private var footer: some View {
        HStack {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(.cyan)

            Text("NOVA EMULATOR")
                .tracking(1.5)

            Spacer()

            Text("\(library.games.count) игр")
                .foregroundStyle(.white.opacity(0.55))
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.035))
    }
}
