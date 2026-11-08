package xmagemobile.bridge;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.UnmanagedMemory;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;
import org.graalvm.word.WordFactory;

import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

public final class Embedded {

    private static final LinkedBlockingQueue<String> OUTBOX = new LinkedBlockingQueue<>();
    private static volatile ClientSession session;
    private static volatile AtomicBoolean sessionAlive;
    private static volatile DeckLibrary decks;

    private Embedded() {
    }

    @CEntryPoint(name = "xmb_open")
    static int open(IsolateThread thread, CCharPointer decksDir) {
        try {
            close(thread);
            if (decks == null) {
                decks = new DeckLibrary(Paths.get(CTypeConversion.toJavaString(decksDir)));
            }
            OUTBOX.clear();
            AtomicBoolean alive = new AtomicBoolean(true);
            ClientSession s = new ClientSession(new Outbox() {
                @Override
                public boolean isOpen() {
                    return alive.get();
                }

                @Override
                public void send(String message) {
                    OUTBOX.offer(message);
                }
            }, decks, "beta.xmage.today", 17171);
            session = s;
            sessionAlive = alive;
            s.hello();
            return 0;
        } catch (Throwable e) {
            e.printStackTrace();
            return 1;
        }
    }

    @CEntryPoint(name = "xmb_send")
    static int send(IsolateThread thread, CCharPointer json) {
        ClientSession s = session;
        if (s == null) {
            return 1;
        }
        try {
            JsonObject o = JsonParser.parseString(CTypeConversion.toJavaString(json)).getAsJsonObject();
            s.handle(o);
            return 0;
        } catch (RuntimeException e) {
            s.error("Bad message: " + e.getMessage());
            return 2;
        }
    }

    @CEntryPoint(name = "xmb_poll")
    static CCharPointer poll(IsolateThread thread, int timeoutMillis) {
        try {
            String m = OUTBOX.poll(timeoutMillis, TimeUnit.MILLISECONDS);
            if (m == null) {
                return WordFactory.nullPointer();
            }
            byte[] bytes = m.getBytes(StandardCharsets.UTF_8);
            CCharPointer out = UnmanagedMemory.malloc(bytes.length + 1);
            for (int i = 0; i < bytes.length; i++) {
                out.write(i, bytes[i]);
            }
            out.write(bytes.length, (byte) 0);
            return out;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return WordFactory.nullPointer();
        }
    }

    @CEntryPoint(name = "xmb_free")
    static void free(IsolateThread thread, CCharPointer pointer) {
        if (pointer.isNonNull()) {
            UnmanagedMemory.free(pointer);
        }
    }

    @CEntryPoint(name = "xmb_close")
    static void close(IsolateThread thread) {
        ClientSession s = session;
        AtomicBoolean alive = sessionAlive;
        session = null;
        sessionAlive = null;
        if (alive != null) {
            alive.set(false);
        }
        if (s != null) {
            s.closeAndWait();
        }
    }
}
