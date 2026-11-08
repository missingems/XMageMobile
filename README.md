# XMage Mobile

A native SwiftUI client for [XMage](https://github.com/magefree/mage), the open-source Magic: The Gathering rules engine, for iPhone, iPad and iPhone Duo.

XMage's own client is a Java Swing desktop app that talks to the server over JBoss Remoting with Java serialization. Rather than re-implement that protocol in Swift, this project runs a small **bridge** next to the server. The bridge uses XMage's own client library and re-exposes the game as JSON over a WebSocket. The iOS app renders the board and sends your choices back.

```
iPhone / iPad ──WebSocket JSON──▶ bridge (Java) ──JBoss Remoting──▶ XMage server
```

The bridge can also run **inside the app**. GraalVM native-image compiles it, together with XMage's client classes, into a static iOS library (`XMageBridge.xcframework`). The app then talks straight to a public server such as xmage.today, with no Mac in between:

```
iPhone / iPad ──in-process JSON──▶ built-in bridge (native) ──JBoss Remoting──▶ XMage server
```

The rules engine, AI and card implementations all stay in XMage.

## Repository layout

| Path | What it is |
|---|---|
| `app/` | SwiftUI app for iOS and iPadOS 27 (XcodeGen spec in `project.yml`) |
| `bridge/` | Java 21 WebSocket bridge (Gradle), compiled against XMage's release jars |
| `schema/PROTOCOL.md` | The bridge ⇄ app JSON contract |
| `scripts/` | Fetch XMage, run the server, run the bridge |
| `decks/` | Decks bundled with the app, listed under **My Decks** (XMage `.dck` format) |
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

In the app, turn on **Use a Mac Bridge**, set **Bridge** to your Mac's address (`localhost` in the simulator), keep **XMage Server** at `127.0.0.1`, connect, pick decks and tap **Play vs Computer**.

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

For online tables, `-autoTable create|join|lobby` seats the app. `-autoTableFormat`, `-autoTableDeck`, `-autoBestOf 3` and `-autoTablePassword` configure the table it creates. `-autoSideboard keep|swap` answers the sideboard step on its own.

## Matches and sideboarding

A new table can be a single game or best of three. Between games of a match, the app shows your main deck and sideboard, and you tap cards to move copies across before the server's three-minute window runs out. The bridge only accepts swaps between the two lists, and submits your deck unchanged if the app doesn't answer in time.

## Your own decks

Put `.dck` files in `decks/My Decks/` and they ship with the app, listed first in the deck picker. Each line is `count [SET:number] Card Name`, with `SB:` in front for sideboard cards. Use set codes and collector numbers that XMage knows. `Mono-Black Necro` is a Modern deck imported from Moxfield.

## Built-in engine (no Mac needed)

The app links `app/Frameworks/XMageBridge.xcframework` (git-ignored, about 55 MB per slice). To build it:

```bash
scripts/fetch-xmage.sh        # XMage jars and sample decks
scripts/setup-graalvm.sh      # GraalVM CE 25.5 and the graalvm-mobile iOS kits, checksums verified
scripts/build-ios-bridge.sh   # native-image for iOS device and simulator, then the xcframework
```

- Only about 20 of XMage's client jars go in (no card sets, no Swing client).
- `bridge/src/main/java/mage/remote/SessionImpl.java` is XMage's own class, with `javax.swing.SwingWorker` replaced by a plain thread, because iOS has no `java.desktop`.
- `bridge/native/traced` is the native-image reflection and serialization metadata, recorded with the tracing agent during real games. `bridge/native/serialization` additionally registers every class XMage can send over the wire.
- If you bump `xmageVersion`, rerun the tracing agent against the new jars.

In the app, **Use a Mac Bridge** is off by default, so it connects directly. Turn it on to use `scripts/run-bridge.sh` instead.

## Card images

Card art is never stored in this repository. The app fetches images from [Scryfall](https://scryfall.com) at runtime and caches them on the device.

## Distribution

TestFlight and source only; this app is not published on the App Store. Magic: The Gathering is © Wizards of the Coast. This project is unofficial fan content and is not affiliated with or endorsed by Wizards of the Coast. XMage is MIT-licensed; so is this project.
