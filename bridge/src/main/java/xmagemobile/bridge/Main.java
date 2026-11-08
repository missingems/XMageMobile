package xmagemobile.bridge;

import java.net.InetSocketAddress;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public final class Main {

    public static void main(String[] args) throws Exception {
        int port = 8765;
        List<Path> decks = new ArrayList<>();
        String defaultServer = "127.0.0.1";
        int defaultServerPort = 17171;

        for (int i = 0; i < args.length - 1; i++) {
            switch (args[i]) {
                case "--port" -> port = Integer.parseInt(args[++i]);
                case "--decks" -> decks.add(Paths.get(args[++i]).toAbsolutePath().normalize());
                case "--server" -> defaultServer = args[++i];
                case "--server-port" -> defaultServerPort = Integer.parseInt(args[++i]);
                default -> { }
            }
        }

        if (decks.isEmpty()) {
            decks.add(Paths.get("../vendor/xmage/xmage/mage-client/sample-decks").toAbsolutePath().normalize());
        }
        DeckLibrary library = new DeckLibrary(decks);
        BridgeServer server = new BridgeServer(new InetSocketAddress(port), library, defaultServer, defaultServerPort);
        server.setReuseAddr(true);
        server.start();
        System.out.println("XMage bridge listening on ws://0.0.0.0:" + port + "/ws, " + library.names().size() + " decks from " + library.roots());
    }
}
