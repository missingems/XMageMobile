package xmagemobile.bridge;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import java.net.InetSocketAddress;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

final class BridgeServer extends WebSocketServer {

    private final DeckLibrary decks;
    private final String defaultServer;
    private final int defaultServerPort;
    private final Map<WebSocket, ClientSession> sessions = new ConcurrentHashMap<>();

    BridgeServer(InetSocketAddress address, DeckLibrary decks, String defaultServer, int defaultServerPort) {
        super(address);
        this.decks = decks;
        this.defaultServer = defaultServer;
        this.defaultServerPort = defaultServerPort;
        setConnectionLostTimeout(30);
    }

    @Override
    public void onOpen(WebSocket conn, ClientHandshake handshake) {
        ClientSession session = new ClientSession(conn, decks, defaultServer, defaultServerPort);
        sessions.put(conn, session);
        System.out.println("App connected from " + conn.getRemoteSocketAddress());
        session.hello();
    }

    @Override
    public void onClose(WebSocket conn, int code, String reason, boolean remote) {
        ClientSession session = sessions.remove(conn);
        if (session != null) {
            session.close();
        }
        System.out.println("App disconnected (" + code + " " + reason + ")");
    }

    @Override
    public void onMessage(WebSocket conn, String message) {
        ClientSession session = sessions.get(conn);
        if (session == null) {
            return;
        }
        try {
            JsonObject json = JsonParser.parseString(message).getAsJsonObject();
            session.handle(json);
        } catch (RuntimeException e) {
            session.error("Bad message: " + e.getMessage());
        }
    }

    @Override
    public void onError(WebSocket conn, Exception ex) {
        System.err.println("WebSocket error: " + ex);
    }

    @Override
    public void onStart() {
    }
}
