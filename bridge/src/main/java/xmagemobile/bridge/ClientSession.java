package xmagemobile.bridge;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import mage.cards.decks.DeckCardLists;
import mage.choices.Choice;
import mage.constants.ManaType;
import mage.constants.MatchTimeLimit;
import mage.constants.MultiplayerAttackOption;
import mage.constants.PlayerAction;
import mage.constants.RangeOfInfluence;
import mage.game.match.MatchOptions;
import mage.interfaces.MageClient;
import mage.interfaces.callback.ClientCallback;
import mage.players.PlayerType;
import mage.players.net.UserData;
import mage.remote.Connection;
import mage.remote.Session;
import mage.remote.SessionImpl;
import mage.util.MultiAmountMessage;
import mage.utils.MageVersion;
import mage.view.AbilityPickerView;
import mage.view.CardsView;
import mage.view.ChatMessage;
import mage.view.GameClientMessage;
import mage.view.GameEndView;
import mage.view.GameTypeView;
import mage.view.GameView;
import mage.view.TableClientMessage;
import mage.view.TableView;
import org.java_websocket.WebSocket;

import java.io.Serializable;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class ClientSession implements MageClient {

    private static final MageVersion VERSION = new MageVersion(MageClient.class);
    private static final String GAME_TYPE = "Two Player Duel";
    private static final String DECK_TYPE = "Constructed - Freeform Unlimited";

    private final WebSocket socket;
    private final DeckLibrary decks;
    private final String defaultServer;
    private final int defaultServerPort;
    private final ExecutorService calls = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "bridge-calls");
        t.setDaemon(true);
        return t;
    });

    private volatile Session session;
    private volatile String username;
    private volatile UUID roomId;
    private volatile UUID gameId;
    private volatile UUID playerId;
    private volatile GameView lastView;

    ClientSession(WebSocket socket, DeckLibrary decks, String defaultServer, int defaultServerPort) {
        this.socket = socket;
        this.decks = decks;
        this.defaultServer = defaultServer;
        this.defaultServerPort = defaultServerPort;
    }

    void hello() {
        JsonObject o = message("hello");
        o.addProperty("bridgeVersion", "0.1.0");
        o.addProperty("xmageVersion", VERSION.toString());
        o.addProperty("defaultServer", defaultServer);
        o.addProperty("defaultPort", defaultServerPort);
        send(o);
        JsonObject d = message("decks");
        d.add("names", ViewMapper.strings(decks.names()));
        send(d);
    }

    void handle(JsonObject json) {
        String type = json.get("type").getAsString();
        calls.submit(() -> {
            try {
                dispatch(type, json);
            } catch (Throwable e) {
                e.printStackTrace();
                error(type + " failed: " + e.getMessage());
            }
        });
    }

    private void dispatch(String type, JsonObject json) {
        switch (type) {
            case "connect" -> connect(
                    optString(json, "server", defaultServer),
                    json.has("port") ? json.get("port").getAsInt() : defaultServerPort,
                    optString(json, "username", "Mobile"));
            case "disconnect" -> disconnect();
            case "startAIGame" -> startAIGame(optString(json, "deck", null), optString(json, "opponentDeck", null));
            case "respondUUID" -> requireSession().sendPlayerUUID(game(json), UUID.fromString(json.get("id").getAsString()));
            case "respondBoolean" -> requireSession().sendPlayerBoolean(game(json), json.get("value").getAsBoolean());
            case "respondInteger" -> requireSession().sendPlayerInteger(game(json), json.get("value").getAsInt());
            case "respondString" -> requireSession().sendPlayerString(game(json), json.get("value").getAsString());
            case "respondManaType" -> requireSession().sendPlayerManaType(game(json), playerId, manaType(json.get("manaType").getAsString()));
            case "playerAction" -> requireSession().sendPlayerAction(PlayerAction.valueOf(json.get("action").getAsString()), game(json), null);
            case "leaveGame" -> leaveGame();
            default -> error("Unknown message type " + type);
        }
    }

    private void connect(String server, int port, String name) {
        disconnect();
        status("connecting", "Connecting to " + server + ":" + port);
        SessionImpl s = new SessionImpl(this);
        Connection con = new Connection();
        con.setHost(server);
        con.setPort(port);
        con.setUsername(name);
        con.setProxyType(Connection.ProxyType.NONE);
        con.setUserData(UserData.getDefaultUserDataView());
        session = s;
        username = name;
        if (!s.connectStart(con)) {
            session = null;
            String reason = s.getLastError();
            status("error", reason == null || reason.isEmpty() ? "Couldn't connect to " + server + ":" + port : ViewMapper.plain(reason));
            return;
        }
        roomId = s.getMainRoomId();
        JsonObject o = message("status");
        o.addProperty("state", "connected");
        o.addProperty("message", "Connected as " + name);
        o.addProperty("server", server);
        o.addProperty("username", name);
        send(o);
    }

    private void disconnect() {
        Session s = session;
        session = null;
        gameId = null;
        if (s != null && s.isConnected()) {
            s.connectStop(false, false);
        }
    }

    void close() {
        calls.submit(this::disconnect);
        calls.shutdown();
    }

    private void leaveGame() {
        Session s = session;
        UUID g = gameId;
        if (s != null && g != null) {
            s.sendPlayerAction(PlayerAction.CONCEDE, g, null);
            s.quitMatch(g);
        }
        gameId = null;
    }

    private void startAIGame(String deckName, String opponentDeckName) {
        Session s = requireSession();
        String mine = deckName != null ? deckName : decks.randomName("AI");
        String theirs = opponentDeckName != null ? opponentDeckName : decks.randomName("AI");
        Optional<DeckCardLists> myDeck = decks.load(mine);
        Optional<DeckCardLists> aiDeck = decks.load(theirs);
        if (myDeck.isEmpty() || aiDeck.isEmpty()) {
            error("Couldn't load deck " + (myDeck.isEmpty() ? mine : theirs));
            return;
        }

        GameTypeView gameType = s.getGameTypes().stream()
                .filter(t -> t.getName().equals(GAME_TYPE))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Server has no " + GAME_TYPE));

        List<PlayerType> offered = java.util.Arrays.asList(s.getPlayerTypes());
        Optional<PlayerType> ai = java.util.stream.Stream.of(PlayerType.COMPUTER_MAD, PlayerType.COMPUTER_MONTE_CARLO)
                .filter(offered::contains)
                .findFirst();
        if (ai.isEmpty()) {
            error("This server doesn't allow games against the computer.");
            return;
        }

        MatchOptions options = new MatchOptions(username + " vs Computer", gameType.getName(), false);
        options.getPlayerTypes().add(PlayerType.HUMAN);
        options.getPlayerTypes().add(ai.get());
        options.setDeckType(DECK_TYPE);
        options.setLimited(false);
        options.setAttackOption(MultiplayerAttackOption.MULTIPLE);
        options.setRange(RangeOfInfluence.ALL);
        options.setWinsNeeded(1);
        options.setMatchTimeLimit(MatchTimeLimit.NONE);
        options.setQuitRatio(100);
        options.setMinimumRating(0);

        TableView table = s.createTable(roomId, options);
        if (table == null) {
            error("Server refused to create a table: " + ViewMapper.plain(s.getLastError()));
            return;
        }
        UUID tableId = table.getTableId();
        if (!s.joinTable(roomId, tableId, username, PlayerType.HUMAN, 1, myDeck.get(), "")) {
            error("Couldn't join the table with " + mine + ": " + ViewMapper.plain(s.getLastError()));
            s.removeTable(roomId, tableId);
            return;
        }
        if (!s.joinTable(roomId, tableId, "Computer", ai.get(), 4, aiDeck.get(), "")) {
            error("Couldn't seat the computer (" + ai.get() + ") with " + theirs + ": " + ViewMapper.plain(s.getLastError()));
            s.removeTable(roomId, tableId);
            return;
        }
        JsonObject o = message("tableReady");
        o.addProperty("deck", myDeck.get().getName());
        o.addProperty("opponentDeck", aiDeck.get().getName());
        send(o);
        if (!s.startMatch(roomId, tableId)) {
            error("Couldn't start the match: " + ViewMapper.plain(s.getLastError()));
        }
    }

    @Override
    public MageVersion getVersion() {
        return VERSION;
    }

    @Override
    public void connected(String message) {
    }

    @Override
    public void disconnected(boolean askToReconnect, boolean keepMySessionActive) {
        status("disconnected", "Disconnected from server");
    }

    @Override
    public void showMessage(String message) {
        info(message);
    }

    @Override
    public void showError(String message) {
        error(message);
    }

    @Override
    public void onNewConnection() {
    }

    @Override
    @SuppressWarnings("unchecked")
    public void onCallback(ClientCallback callback) {
        try {
            callback.decompressData();
            Object data = callback.getData();
            switch (callback.getMethod()) {
                case START_GAME -> {
                    TableClientMessage m = (TableClientMessage) data;
                    gameId = m.getGameId();
                    playerId = m.getPlayerId();
                    JsonObject o = message("gameStarted");
                    o.addProperty("gameId", ViewMapper.str(gameId));
                    o.addProperty("playerId", ViewMapper.str(playerId));
                    send(o);
                    calls.submit(() -> {
                        Session s = session;
                        if (s != null) {
                            s.joinGame(m.getGameId());
                        }
                    });
                }
                case GAME_INIT -> {
                    gameId = callback.getObjectId();
                    sendGame((GameView) data, null);
                    calls.submit(() -> {
                        Session s = session;
                        if (s != null) {
                            s.getGameChatId(gameId).ifPresent(s::joinChat);
                        }
                    });
                }
                case GAME_UPDATE -> sendGame((GameView) data, null);
                case GAME_UPDATE_AND_INFORM -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    waiting(m.getMessage());
                }
                case GAME_INFORM_PERSONAL -> info(((GameClientMessage) data).getMessage());
                case GAME_ERROR -> error(String.valueOf(data));
                case GAME_SELECT -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    JsonObject p = prompt("select", m.getMessage(), m.getOptions());
                    p.addProperty("doneLabel", label(m.getOptions(), "UI.right.btn.text", "Done"));
                    sendPrompt(p);
                }
                case GAME_TARGET -> {
                    GameClientMessage m = (GameClientMessage) data;
                    Set<UUID> targets = m.getTargets();
                    sendGame(m.getGameView(), targets);
                    JsonObject p = prompt("target", m.getMessage(), m.getOptions());
                    p.addProperty("required", m.isFlag());
                    JsonArray ids = new JsonArray();
                    if (targets != null) {
                        targets.forEach(id -> ids.add(id.toString()));
                    }
                    p.add("targetIds", ids);
                    CardsView cards = m.getCardsView1();
                    if (cards != null && !cards.isEmpty()) {
                        p.add("cards", new ViewMapper(gameId, playerId, targets).cards(cards, m.getGameView(), null));
                    }
                    sendPrompt(p);
                }
                case GAME_ASK -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    JsonObject p = prompt("ask", m.getMessage(), m.getOptions());
                    p.addProperty("yesLabel", label(m.getOptions(), "UI.left.btn.text", "Yes"));
                    p.addProperty("noLabel", label(m.getOptions(), "UI.right.btn.text", "No"));
                    sendPrompt(p);
                }
                case GAME_PLAY_MANA -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    sendPrompt(prompt("mana", m.getMessage(), m.getOptions()));
                }
                case GAME_PLAY_XMANA -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    sendPrompt(prompt("xmana", m.getMessage(), m.getOptions()));
                }
                case GAME_GET_AMOUNT -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    JsonObject p = prompt("amount", m.getMessage(), m.getOptions());
                    p.addProperty("min", m.getMin());
                    p.addProperty("max", m.getMax());
                    sendPrompt(p);
                }
                case GAME_GET_MULTI_AMOUNT -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    JsonObject p = prompt("multiAmount", m.getMessage(), m.getOptions());
                    p.addProperty("min", m.getMin());
                    p.addProperty("max", m.getMax());
                    JsonArray rows = new JsonArray();
                    for (MultiAmountMessage row : m.getMessages()) {
                        JsonObject r = new JsonObject();
                        r.addProperty("label", ViewMapper.plain(row.message));
                        r.addProperty("min", row.min);
                        r.addProperty("max", row.max);
                        r.addProperty("value", row.defaultValue);
                        rows.add(r);
                    }
                    p.add("rows", rows);
                    sendPrompt(p);
                }
                case GAME_CHOOSE_CHOICE -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    Choice choice = m.getChoice();
                    String text = choice.getMessage();
                    if (choice.getSubMessage() != null && !choice.getSubMessage().isEmpty()) {
                        text = text + "\n" + choice.getSubMessage();
                    }
                    JsonObject p = prompt("choice", text, m.getOptions());
                    p.addProperty("required", choice.isRequired());
                    JsonArray choices = new JsonArray();
                    if (choice.isKeyChoice()) {
                        for (Map.Entry<String, String> e : choice.getKeyChoices().entrySet()) {
                            choices.add(choiceItem(e.getKey(), e.getValue()));
                        }
                    } else {
                        for (String c : choice.getChoices()) {
                            choices.add(choiceItem(c, c));
                        }
                    }
                    p.add("choices", choices);
                    sendPrompt(p);
                }
                case GAME_CHOOSE_ABILITY -> {
                    AbilityPickerView v = (AbilityPickerView) data;
                    sendGame(v.getGameView(), null);
                    JsonObject p = prompt("ability", v.getMessage(), null);
                    JsonArray choices = new JsonArray();
                    for (Map.Entry<UUID, String> e : v.getChoices().entrySet()) {
                        choices.add(choiceItem(e.getKey().toString(), e.getValue()));
                    }
                    p.add("choices", choices);
                    sendPrompt(p);
                }
                case GAME_CHOOSE_PILE -> {
                    GameClientMessage m = (GameClientMessage) data;
                    sendGame(m.getGameView(), null);
                    ViewMapper mapper = new ViewMapper(gameId, playerId, null);
                    JsonObject p = prompt("pile", m.getMessage(), m.getOptions());
                    p.add("pile1", mapper.cards(m.getCardsView1(), m.getGameView(), null));
                    p.add("pile2", mapper.cards(m.getCardsView2(), m.getGameView(), null));
                    sendPrompt(p);
                }
                case GAME_OVER -> {
                    GameClientMessage m = (GameClientMessage) data;
                    JsonObject o = message("gameOver");
                    o.addProperty("text", ViewMapper.plain(m.getMessage()));
                    send(o);
                }
                case END_GAME_INFO -> {
                    GameEndView v = (GameEndView) data;
                    JsonObject o = message("gameEnd");
                    o.addProperty("won", v.hasWon());
                    o.addProperty("gameInfo", ViewMapper.plain(v.getGameInfo()));
                    o.addProperty("matchInfo", ViewMapper.plain(v.getMatchInfo()));
                    send(o);
                }
                case CHATMESSAGE -> {
                    ChatMessage m = (ChatMessage) data;
                    JsonObject o = message("log");
                    o.addProperty("text", ViewMapper.plain(m.getMessage()));
                    o.addProperty("kind", m.getMessageType() == null ? null : m.getMessageType().name());
                    o.addProperty("turnInfo", m.getTurnInfo());
                    o.addProperty("user", m.getUsername());
                    send(o);
                }
                case SHOW_USERMESSAGE -> info(String.join(" — ", (List<String>) data));
                case SERVER_MESSAGE -> info(String.valueOf(data));
                default -> { }
            }
        } catch (Throwable e) {
            e.printStackTrace();
            error("Callback " + callback.getMethod() + " failed: " + e.getMessage());
        }
    }

    private void sendGame(GameView view, Set<UUID> targets) {
        if (view == null) {
            return;
        }
        lastView = view;
        JsonObject o = message("game");
        o.add("state", new ViewMapper(gameId, playerId, targets).game(view));
        send(o);
    }

    private JsonObject prompt(String kind, String text, Map<String, Serializable> options) {
        JsonObject p = new JsonObject();
        p.addProperty("kind", kind);
        p.addProperty("gameId", ViewMapper.str(gameId));
        p.addProperty("message", ViewMapper.plain(text));
        if (options != null && options.get("UI.special.btn.text") instanceof String special) {
            p.addProperty("specialLabel", special);
        }
        return p;
    }

    private void sendPrompt(JsonObject prompt) {
        JsonObject o = message("prompt");
        o.add("prompt", prompt);
        send(o);
    }

    private void waiting(String text) {
        JsonObject o = message("waiting");
        o.addProperty("text", ViewMapper.plain(text));
        send(o);
    }

    private static String label(Map<String, Serializable> options, String key, String fallback) {
        if (options != null && options.get(key) instanceof String s && !s.isEmpty()) {
            return ViewMapper.plain(s);
        }
        return fallback;
    }

    private static JsonObject choiceItem(String id, String label) {
        JsonObject o = new JsonObject();
        o.addProperty("id", id);
        o.addProperty("label", ViewMapper.plain(label));
        return o;
    }

    private static ManaType manaType(String code) {
        return switch (code) {
            case "W" -> ManaType.WHITE;
            case "U" -> ManaType.BLUE;
            case "B" -> ManaType.BLACK;
            case "R" -> ManaType.RED;
            case "G" -> ManaType.GREEN;
            default -> ManaType.COLORLESS;
        };
    }

    private Session requireSession() {
        Session s = session;
        if (s == null) {
            throw new IllegalStateException("Not connected");
        }
        return s;
    }

    private UUID game(JsonObject json) {
        if (json.has("gameId") && !json.get("gameId").isJsonNull()) {
            return UUID.fromString(json.get("gameId").getAsString());
        }
        if (gameId == null) {
            throw new IllegalStateException("No game in progress");
        }
        return gameId;
    }

    private static String optString(JsonObject json, String key, String fallback) {
        return json.has(key) && !json.get(key).isJsonNull() ? json.get(key).getAsString() : fallback;
    }

    private void status(String state, String text) {
        JsonObject o = message("status");
        o.addProperty("state", state);
        o.addProperty("message", text);
        send(o);
    }

    private void info(String text) {
        JsonObject o = message("info");
        o.addProperty("text", ViewMapper.plain(text));
        send(o);
    }

    void error(String text) {
        JsonObject o = message("error");
        o.addProperty("text", ViewMapper.plain(text));
        send(o);
    }

    private static JsonObject message(String type) {
        JsonObject o = new JsonObject();
        o.addProperty("type", type);
        return o;
    }

    private void send(JsonObject o) {
        if (socket.isOpen()) {
            socket.send(o.toString());
        }
    }
}
