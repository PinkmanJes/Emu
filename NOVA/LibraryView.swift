
import SwiftUI
import UniformTypeIdentifiers

struct Game: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var filename: String
    var system: String
    var fileURL: URL
}

@MainActor
final class GameLibrary: ObservableObject {
    @Published var games: [Game] = []

    private let key = "nova.library.v1"

    init() {
        load()
    }

    func importFiles(_ urls: [URL]) {
        let fm = FileManager.default

        guard let docs = fm.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return }

        let folder = docs.appendingPathComponent(
            "Games",
            isDirectory: true
        )

        try? fm.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        for source in urls {
            let access = source.startAccessingSecurityScopedResource()
            defer {
                if access {
                    source.stopAccessingSecurityScopedResource()
                }
            }

            let destination = folder.appendingPathComponent(
                source.lastPathComponent
            )

            do {
                if !fm.fileExists(atPath: destination.path) {
                    try fm.copyItem(at: source, to: destination)
                }

                let ext = destination.pathExtension.lowercased()

                let system = [
                    "rvz", "gcm", "gcz", "wbfs"
                ].contains(ext) ? "GAMECUBE" : "PS2"

                if !games.contains(where: {
                    $0.fileURL == destination
                }) {
                    games.append(
                        Game(
                            title: destination
                                .deletingPathExtension()
                                .lastPathComponent,
                            filename: destination.lastPathComponent,
                            system: system,
                            fileURL: destination
                        )
                    )
                }
            } catch {
                print("NOVA import failed: \(error)")
            }
        }

        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(games) else {
            return
        }

        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode(
                [Game].self,
                from: data
            )
        else {
            return
        }

        games = saved.filter {
            FileManager.default.fileExists(atPath: $0.fileURL.path)
        }
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibrary()
    @State private var showImporter = false
    @State private var search = ""
    @State private var selectedFilter = "ALL"

    private let filters = ["ALL", "GAMECUBE", "PS2"]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private let accent = Color(
        red: 0.55,
        green: 0.39,
        blue: 1.0
    )

    private var visibleGames: [Game] {
        library.games.filter {
            (selectedFilter == "ALL" || $0.system == selectedFilter) &&
            (search.isEmpty ||
             $0.title.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(
                    red: 0.045,
                    green: 0.047,
                    blue: 0.075
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        VStack(alignment: .leading, spacing: 5) {
                            Text("YOUR GAME SPACE")
                                .font(.system(
                                    size: 11,
                                    weight: .bold,
                                    design: .rounded
                                ))
                                .tracking(2.2)
                                .foregroundStyle(accent)

                            Text("Library")
                                .font(.system(
                                    size: 34,
                                    weight: .bold,
                                    design: .rounded
                                ))
                                .foregroundStyle(.white)

                            Text("Your games. Your space.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.52))
                        }

                        searchField
                        filterBar

                        if visibleGames.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(
                                columns: columns,
                                spacing: 18
                            ) {
                                ForEach(visibleGames) { game in
                                    gameCard(game)
                                }
                            }
                        }

                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            .overlay(alignment: .topTrailing) {
    Text("\(Int(geometry.size.width)) × \(Int(geometry.size.height))")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.yellow)
        .padding(8)
        .background(.black)
}
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                library.importFiles(urls)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent,
                                Color(
                                    red: 0.22,
                                    green: 0.72,
                                    blue: 0.98
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "sparkles.tv.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 1) {
                Text("NOVA")
                    .font(.system(
                        size: 17,
                        weight: .black,
                        design: .rounded
                    ))
                    .tracking(2)
                    .foregroundStyle(.white)

                Text("EMULATOR PROJECT")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer(minLength: 0)

            Button {
                showImporter = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        .white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
            }
            .accessibilityLabel("Import games")
        }
        .frame(maxWidth: .infinity)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.45))

            TextField("Search your library", text: $search)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            .white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(
                        filter == "ALL"
                        ? "All games"
                        : filter == "PS2"
                            ? "PlayStation 2"
                            : "GameCube"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        selectedFilter == filter
                        ? .white
                        : .white.opacity(0.5)
                    )
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        selectedFilter == filter
                        ? accent.opacity(0.9)
                        : .white.opacity(0.055),
                        in: Capsule()
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(accent.opacity(0.12))
                    .frame(width: 84, height: 84)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 31))
                    .foregroundStyle(accent)
            }

            Text("Your next adventure starts here")
                .font(.system(
                    size: 17,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(.white)

            Text("Import game files from the Files app to build your library.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                showImporter = true
            } label: {
                Label(
                    "Import games",
                    systemImage: "plus.circle.fill"
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [
                            accent,
                            Color.blue.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 18)
        .background(
            .white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.055), lineWidth: 1)
        }
    }

    private func gameCard(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 17)
                    .fill(
                        LinearGradient(
                            colors: game.system == "PS2"
                            ? [
                                Color(
                                    red: 0.24,
                                    green: 0.14,
                                    blue: 0.45
                                ),
                                Color(
                                    red: 0.09,
                                    green: 0.11,
                                    blue: 0.23
                                )
                            ]
                            : [
                                Color(
                                    red: 0.10,
                                    green: 0.35,
                                    blue: 0.42
                                ),
                                Color(
                                    red: 0.08,
                                    green: 0.12,
                                    blue: 0.24
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(0.78, contentMode: .fit)

                Image(
                    systemName: game.system == "PS2"
                    ? "playstation.logo"
                    : "cube.transparent.fill"
                )
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(game.system)
                    .font(.system(size: 8, weight: .black))
                    .tracking(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.3), in: Capsule())
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(10)
            }

            Text(game.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text("Imported · Core not connected yet")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(spacing: 7) {
            Rectangle()
                .fill(.white.opacity(0.07))
                .frame(height: 1)

            HStack {
                Image(systemName: "wave.3.right")
                    .foregroundStyle(accent)

                Text("NOVA · EARLY DEVELOPMENT BUILD")
                    .foregroundStyle(.white.opacity(0.35))

                Spacer(minLength: 0)

                Text("0.1")
                    .foregroundStyle(.white.opacity(0.35))
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
        }
        .padding(.top, 12)
    }
}
