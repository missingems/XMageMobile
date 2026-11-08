# XMage Mobile

A native SwiftUI client for [XMage](https://github.com/magefree/mage), the open-source Magic: The Gathering rules engine, for iPhone, iPad and iPhone Duo.

XMage's own client is a Java Swing desktop app that talks to the server over JBoss Remoting with Java serialization. Rather than re-implement that protocol in Swift, this project runs a small **bridge** next to the server. The bridge uses XMage's own client library and re-exposes the game as JSON over a WebSocket. The iOS app renders the board and sends your choices back.

```
iPhone / iPad ──WebSocket JSON──▶ bridge (Java) ──JBoss Remoting──▶ XMage server
```

The rules engine, AI and card implementations all stay in XMage.

## Repository layout

| Path | What it is |
|---|---|
| `app/` | SwiftUI app for iOS and iPadOS 27 (XcodeGen spec in `project.yml`) |
| `bridge/` | Java 21 WebSocket bridge (Gradle), compiled against XMage's release jars |
| `schema/PROTOCOL.md` | The bridge ⇄ app JSON contract |
| `scripts/` | Fetch XMage, run the server, run the bridge |
| `vendor/` | Downloaded XMage release (git-ignored) |

## Running it locally

Requirements: macOS, Homebrew `openjdk@21`, Xcode 27.1, `xcodegen`, `gh`.

```bash
brew install openjdk@21 xcodegen
scripts/fetch-xmage.sh      # downloads the XMage release pinned in bridge/gradle.properties
scripts/run-server.sh       # XMage server on 127.0.0.1:17171
scripts/run-bridge.sh       # bridge on ws://0.0.0.0:8765/ws
cd app && xcodegen generate && open XMageMobile.xcodeproj
```

In the app, set **Bridge** to your Mac's address (`localhost` in the simulator), keep **XMage Server** at `127.0.0.1`, connect, pick decks and tap **Play vs Computer**.

The XMage version is pinned in one place, `bridge/gradle.properties` (`xmageVersion`). The server rejects clients built against a different release, so bump it together with `scripts/fetch-xmage.sh`.

### Notes

- XMage officially targets Java 8. On Java 21 both the server and the bridge need the `--add-opens` flags in `scripts/java-env.sh`, or the connection resets during serialization.
- `fetch-xmage.sh` binds the server to `127.0.0.1`; with `0.0.0.0` it can advertise a link-local address that the bridge can't reach.

### Debug launch arguments

For screenshots and testing without touching the screen (Debug builds only):

```
-autoStart YES -username Jun -deck "AI/FastRedHaste.dck" -opponentDeck "AI/White Honor.dck" -autopilotTurns 6
```

`-autoStart` connects and starts a game against the computer. `-autopilotTurns N` plays lands and spells and passes priority until turn N, then hands control back.

## Card images

Card art is never stored in this repository. The app fetches images from [Scryfall](https://scryfall.com) at runtime and caches them on the device.

## Distribution

TestFlight and source only; this app is not published on the App Store. Magic: The Gathering is © Wizards of the Coast. This project is unofficial fan content and is not affiliated with or endorsed by Wizards of the Coast. XMage is MIT-licensed; so is this project.
