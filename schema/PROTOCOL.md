# Bridge ⇄ App protocol

One WebSocket per app session: `ws://<bridge-host>:8765/ws`.
Every frame is a JSON object with a `type` field.

## App → Bridge

| type | fields | meaning |
|---|---|---|
| `connect` | `server`, `port`, `username` | Log in to an XMage server through the bridge |
| `startAIGame` | `deck` (optional sample deck name), `opponentDeck` (optional) | Create a two-player table vs the computer and start it |
| `respondUUID` | `gameId`, `id` | Pick a card, permanent, player or ability (also "play this card" while holding priority) |
| `respondBoolean` | `gameId`, `value` | Answer a yes/no question, or `false` = "Done / Pass" at priority |
| `respondInteger` | `gameId`, `value` | Answer an amount prompt |
| `respondString` | `gameId`, `value` | Answer a choice prompt |
| `respondManaType` | `gameId`, `playerId`, `manaType` | Pay with a mana type from the pool |
| `playerAction` | `gameId`, `action` | XMage `PlayerAction` name, e.g. `PASS_PRIORITY_UNTIL_NEXT_TURN`, `CONCEDE` |

## Bridge → App

| type | fields | meaning |
|---|---|---|
| `status` | `state` (`connecting`, `connected`, `disconnected`, `error`), `message` | Connection state |
| `decks` | `names` | Sample decks the bridge can offer |
| `gameStarted` | `gameId`, `playerId` | A game began; `playerId` is you |
| `game` | `state` (see `GameState`) | Full board snapshot; replace, don't merge |
| `prompt` | `prompt` (see `Prompt`) | The server is waiting on you |
| `message` | `text` | Game log line / inform |
| `gameOver` | `text`, `won` | Game ended |

## GameState

```json
{
  "gameId": "…", "turn": 3, "phase": "PRECOMBAT_MAIN", "step": "PRECOMBAT_MAIN",
  "activePlayerId": "…", "priorityPlayerId": "…",
  "players": [ Player ], "hand": [ Card ], "stack": [ Card ],
  "combat": [ { "attackerIds": ["…"], "blockerIds": ["…"], "defenderId": "…" } ]
}
```

`Player`: `id`, `name`, `life`, `libraryCount`, `handCount`, `isYou`, `isActive`,
`hasPriority`, `manaPool` (`{W,U,B,R,G,C}` ints), `counters` (`[{name,count}]`),
`battlefield` (`[Card]`), `graveyard` (`[Card]`), `exile` (`[Card]`), `commander` (`[Card]`).

`Card`: `id`, `name`, `set`, `number`, `manaCost` (e.g. `"{2}{U}{U}"`), `types` (`["Creature"]`),
`subtypes`, `rules` (`[String]`), `power`, `toughness`, `loyalty`, `defense`,
`tapped`, `damage`, `summoningSick`, `counters`, `attachedTo`, `isToken`,
`playable` (you can act on it now), `choosable` (valid target in the current prompt),
`selected`, `controllerId`.

Card art is never shipped by the bridge or the app repo: the app fetches
`https://api.scryfall.com/cards/<set>/<number>?format=image` at runtime.

## Prompt

```json
{ "kind": "priority|target|ask|choice|amount|mana|ability|pile|info",
  "gameId": "…", "message": "Play spells and abilities.",
  "required": false,
  "choices": [ { "id": "…", "label": "…" } ],
  "min": 0, "max": 0,
  "options": { "yesLabel": "Yes", "noLabel": "No" } }
```

- `priority` → tap a `playable` card (`respondUUID`) or pass (`respondBoolean false`).
- `target` → tap a `choosable` card/player (`respondUUID`); `required:false` allows Done (`respondBoolean false`).
- `ask` → `respondBoolean`.
- `choice` / `ability` → pick from `choices` (`respondString` / `respondUUID`).
- `amount` → `respondInteger` between `min` and `max`.
- `mana` → tap a land/source (`respondUUID`) or a pool mana type (`respondManaType`), or cancel (`respondBoolean false`).
