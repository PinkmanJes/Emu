
import SwiftUI
import UniformTypeIdentifiers

struct Game: Identifiable, Codable {
    var id = UUID()
    var title: String
    var system: String
    var fileURL: URL
}

final class GameLibrary: ObservableObject {
    @Published var games: [Game] = []

    func add(url: URL) {
        let game = Game(
            title: url.deletingPathExtension().lastPathComponent,
            system: "Imported",
            fileURL: url
        )
        games.append(game)
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibrary()
    @State private var showImporter = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.035, green: 0.045, blue: 0.07)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("NOVA")
                                .font(.system(size: 34, weight: .black))
                                .foregroundStyle(.white)

                            Text("GAME LIBRARY")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(3)
                                .foregroundStyle(.cyan)
                        }

                        Spacer()

                        Button {
                            showImporter = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 48, height: 48)
                                .background(.cyan)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Text("YOUR GAMES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.gray)

                    if library.games.isEmpty {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 54))
                                .foregroundStyle(.cyan)

                            Text("Your library is empty")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Import a game file to get started.")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)

                            Button("IMPORT GAME") {
                                showImporter = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 130), spacing: 16)
                                ],
                                spacing: 16
                            ) {
                                ForEach(library.games) { game in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 34))
                                            .foregroundStyle(.cyan)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 120)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))

                                        Text(game.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(2)

                                        Text(game.system)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Text("NOVA EMULATOR")
                        Spacer()
                        Text("\(library.games.count) GAMES")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.gray)
                }
                .padding(24)

                VStack {
                    HStack {
                        Spacer()

                        Text("\(Int(geometry.size.width)) × \(Int(geometry.size.height))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(8)
                            .background(.black)
                    }

                    Spacer()
                }
                .padding(8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    library.add(url: url)
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
        }
    }
}

@main
struct NOVAApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
    }
}
