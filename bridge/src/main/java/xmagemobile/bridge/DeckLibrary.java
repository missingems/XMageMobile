package xmagemobile.bridge;

import mage.cards.decks.DeckCardInfo;
import mage.cards.decks.DeckCardLists;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

final class DeckLibrary {

    private static final Pattern LINE = Pattern.compile("^(SB:\\s*)?(\\d+)\\s+\\[([^:\\]]+):([^\\]]+)]\\s+(.+)$");

    private final Path root;
    private final List<String> names;

    DeckLibrary(Path root) {
        this.root = root;
        List<String> found = new ArrayList<>();
        if (Files.isDirectory(root)) {
            try (Stream<Path> files = Files.walk(root)) {
                files.filter(p -> p.toString().endsWith(".dck"))
                        .map(p -> root.relativize(p).toString())
                        .sorted()
                        .forEach(found::add);
            } catch (IOException e) {
                System.err.println("Can't list decks: " + e);
            }
        }
        this.names = List.copyOf(found);
    }

    Path root() {
        return root;
    }

    List<String> names() {
        return names;
    }

    String randomName(String preferredFolder) {
        List<String> pool = names.stream().filter(n -> n.startsWith(preferredFolder + "/")).toList();
        if (pool.isEmpty()) {
            pool = names;
        }
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
    }

    Optional<DeckCardLists> load(String name) {
        Path file = root.resolve(name).normalize();
        if (!file.startsWith(root) || !Files.isRegularFile(file)) {
            return Optional.empty();
        }
        try {
            DeckCardLists deck = new DeckCardLists();
            deck.setName(file.getFileName().toString().replaceFirst("\\.dck$", ""));
            for (String raw : Files.readAllLines(file, StandardCharsets.UTF_8)) {
                String line = raw.trim();
                if (line.startsWith("NAME:")) {
                    deck.setName(line.substring(5).trim());
                    continue;
                }
                Matcher m = LINE.matcher(line);
                if (!m.matches()) {
                    continue;
                }
                DeckCardInfo info = new DeckCardInfo(m.group(5).trim(), m.group(4).trim(), m.group(3).trim(), Integer.parseInt(m.group(2)));
                if (m.group(1) != null) {
                    deck.getSideboard().add(info);
                } else {
                    deck.getCards().add(info);
                }
            }
            return deck.getCards().isEmpty() ? Optional.empty() : Optional.of(deck);
        } catch (IOException e) {
            return Optional.empty();
        }
    }
}
