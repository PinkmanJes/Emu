
import SwiftUI
import UniformTypeIdentifiers

private enum NOVATheme: String {
    case classic
    case liquidGlass
}

struct Game: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var fileName: String
    var fileURL: URL
    var isFavorite: Bool = false
}

final class GameLibrary: ObservableObject {
    @Published var games: [Game] = [] {
        didSet { save() }
    }

    private let storageKey = "nova.games"

    init() {
        load()
    }

    func addFile(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let folder = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let destination = folder.appendingPathComponent(
                url.lastPathComponent
            )

            if !FileManager.default.fileExists(
                atPath: destination.path
            ) {
                try FileManager.default.copyItem(
                    at: url,
                    to: destination
                )
            }

            guard !games.contains(where: {
                $0.fileName == destination.lastPathComponent
            }) else { return }

            games.append(
                Game(
                    title: destination.deletingPathExtension().lastPathComponent,
                    fileName: destination.lastPathComponent,
                    fileURL: destination
                )
            )
        } catch {
            print("NOVA import error:", error.localizedDescription)
        }
    }

    func toggleFavorite(_ game: Game) {
        guard let index = games.firstIndex(
            where: { $0.id == game.id }
        ) else { return }

        games[index].isFavorite.toggle()
    }

    func remove(_ game: Game) {
        games.removeAll { $0.id == game.id }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(games) else {
            return
        }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([Game].self, from: data)
        else { return }

        games = saved.filter {
            FileManager.default.fileExists(atPath: $0.fileURL.path)
        }
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibrary()

    @AppStorage("nova.theme")
    private var themeName = "classic"

    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var showingImporter = false

    private var isGlass: Bool {
        themeName == NOVATheme.liquidGlass.rawValue
    }

    private var backgroundColor: Color {
        isGlass
        ? Color(red: 0.035, green: 0.045, blue: 0.10)
        : Color(red: 0.035, green: 0.04, blue: 0.075)
    }

    private var accent: Color {
        isGlass
        ? Color(red: 0.66, green: 0.57, blue: 1.0)
        : Color.purple
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredGames: [Game] {
        library.games.filter { game in
            let matchesSearch = searchText.isEmpty ||
                game.title.localizedCaseInsensitiveContains(searchText)

            return matchesSearch &&
                (!favoritesOnly || game.isFavorite)
        }
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        searchBar
                        collectionHeader

                        if filteredGames.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(filteredGames) { game in
                                    GameCard(
                                        game: game,
                                        isGlass: isGlass,
                                        accent: accent,
                                        onFavorite: {
                                            library.toggleFavorite(game)
                                        },
                                        onDelete: {
                                            library.remove(game)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: themeName)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                urls.forEach { library.addFile($0) }
            case .failure(let error):
                print("NOVA picker error:", error.localizedDescription)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if isGlass {
                Circle()
                    .fill(Color.purple.opacity(0.28))
                    .frame(width: 260, height: 260)
                    .blur(radius: 100)
                    .offset(x: -120, y: -280)

                Circle()
                    .fill(Color.blue.opacity(0.20))
                    .frame(width: 280, height: 280)
                    .blur(radius: 110)
                    .offset(x: 150, y: 100)

                LinearGradient(
                    colors: [
                        .white.opacity(0.035),
                        .clear,
                        .purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(accent)

                    Text("NOVA")
                        .font(
                            .system(
                                size: 27,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .tracking(2)
                }

                Text("YOUR GAME LIBRARY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer(minLength: 4)

            // Theme selector
            Menu {
                Button {
                    themeName = NOVATheme.classic.rawValue
                } label: {
                    Label(
                        "NOVA Classic",
                        systemImage: themeName == "classic"
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                }

                Button {
                    themeName = NOVATheme.liquidGlass.rawValue
                } label: {
                    Label(
                        "Liquid Glass",
                        systemImage: themeName == "liquidGlass"
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                }
            } label: {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        if isGlass {
                            Circle().fill(.ultraThinMaterial)
                        } else {
                            Circle().fill(Color.white.opacity(0.07))
                        }
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                .white.opacity(isGlass ? 0.30 : 0.08),
                                lineWidth: 1
                            )
                    }
            }
            .accessibilityLabel("Change appearance")

            Button {
                showingImporter = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        if isGlass {
                            Circle().fill(.ultraThinMaterial)
                        } else {
                            Circle().fill(accent.gradient)
                        }
                    }
                    .overlay {
                        Circle()
                            .fill(accent.opacity(isGlass ? 0.20 : 0))
                    }
                    .overlay {
                        Circle().strokeBorder(
                            .white.opacity(isGlass ? 0.35 : 0),
                            lineWidth: 1
                        )
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Import games")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.55))

            TextField("Search your games...", text: $searchText)
                .font(.system(size: 15))
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background {
            if isGlass {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.055))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: isGlass ? 18 : 15)
                .strokeBorder(
                    .white.opacity(isGlass ? 0.24 : 0.07),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Collection controls

    private var collectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(favoritesOnly ? "FAVORITES" : "YOUR COLLECTION")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.55))

                Text("\(filteredGames.count) games")
                    .font(
                        .system(size: 24, weight: .bold, design: .rounded)
                    )
            }

            Spacer()

            HStack(spacing: 4) {
                filterButton("All", selected: !favoritesOnly) {
                    favoritesOnly = false
                }

                filterButton("★", selected: favoritesOnly) {
                    favoritesOnly = true
                }
            }
            .padding(4)
            .background {
                if isGlass {
                    Capsule().fill(.ultraThinMaterial)
                } else {
                    Capsule().fill(Color.white.opacity(0.06))
                }
            }
            .overlay {
                Capsule().strokeBorder(
                    .white.opacity(isGlass ? 0.22 : 0.06),
                    lineWidth: 1
                )
            }
        }
    }

    private func filterButton(
        _ title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(selected ? 1 : 0.55))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background {
                    if selected {
                        Capsule()
                            .fill(
                                isGlass
                                ? accent.opacity(0.38)
                                : Color.purple.opacity(0.8)
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(
                systemName: searchText.isEmpty
                    ? "square.stack.3d.up"
                    : "magnifyingglass"
            )
            .font(.system(size: 38))
            .foregroundStyle(accent)
            .frame(width: 86, height: 86)
            .background {
                if isGlass {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.purple.opacity(0.12))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(
                        .white.opacity(isGlass ? 0.25 : 0.06),
                        lineWidth: 1
                    )
            }

            Text(
                searchText.isEmpty
                    ? (favoritesOnly
                       ? "No favorites yet"
                       : "Your library is empty")
                    : "No games found"
            )
            .font(.system(size: 19, weight: .bold))

            Text(
                searchText.isEmpty
                    ? "Tap + to import game files from Files."
                    : "Try another search."
            )
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.52))
            .multilineTextAlignment(.center)

            if searchText.isEmpty && !favoritesOnly {
                Button {
                    showingImporter = true
                } label: {
                    Label("Import games", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background {
                            if isGlass {
                                Capsule().fill(.ultraThinMaterial)
                            } else {
                                Capsule().fill(accent.gradient)
                            }
                        }
                        .overlay {
                            Capsule().strokeBorder(
                                .white.opacity(isGlass ? 0.3 : 0),
                                lineWidth: 1
                            )
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 55)
        .padding(.horizontal, 24)
    }
}

// MARK: - Game card

private struct GameCard: View {
    let game: Game
    let isGlass: Bool
    let accent: Color
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: isGlass ? 20 : 17)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.19, blue: 0.57),
                                Color(red: 0.11, green: 0.12, blue: 0.30),
                                Color(red: 0.055, green: 0.065, blue: 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if isGlass {
                    Circle()
                        .fill(accent.opacity(0.38))
                        .frame(width: 95, height: 95)
                        .blur(radius: 30)
                        .offset(x: -35, y: 20)

                    LinearGradient(
                        colors: [.white.opacity(0.16), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: onFavorite) {
                    Image(
                        systemName: game.isFavorite
                            ? "star.fill"
                            : "star"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        game.isFavorite ? .yellow : .white
                    )
                    .frame(width: 34, height: 34)
                    .background {
                        if isGlass {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        } else {
                            RoundedRectangle(cornerRadius: 11)
                                .fill(.black.opacity(0.3))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                .white.opacity(isGlass ? 0.28 : 0),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .padding(9)
            }
            .frame(height: 135)
            .clipShape(RoundedRectangle(cornerRadius: isGlass ? 20 : 17))
            .overlay {
                RoundedRectangle(cornerRadius: isGlass ? 20 : 17)
                    .strokeBorder(
                        .white.opacity(isGlass ? 0.22 : 0.04),
                        lineWidth: 1
                    )
            }

            Text(game.title)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(2)
                .foregroundStyle(.white)
                .padding(.top, 12)

            Text(game.fileName)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .padding(.top, 4)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Imported")
                    .lineLimit(1)

                Spacer(minLength: 0)

                Menu {
                    Button(action: onFavorite) {
                        Label(
                            game.isFavorite
                                ? "Remove favorite"
                                : "Add to favorites",
                            systemImage: "star"
                        )
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label(
                            "Remove from library",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 30, height: 28)
                        .contentShape(Rectangle())
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.green.opacity(0.85))
            .padding(.top, 12)
        }
        .padding(11)
        .background {
            if isGlass {
                RoundedRectangle(cornerRadius: 23)
                    .fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.045))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: isGlass ? 23 : 22)
                .strokeBorder(
                    .white.opacity(isGlass ? 0.22 : 0.065),
                    lineWidth: 1
                )
        }
    }
}
