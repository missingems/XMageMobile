package xmagemobile.bridge;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import mage.ObjectColor;
import mage.view.CardView;
import mage.view.CardsView;
import mage.view.CombatGroupView;
import mage.view.CommandObjectView;
import mage.view.CounterView;
import mage.view.GameView;
import mage.view.ManaPoolView;
import mage.view.PermanentView;
import mage.view.PlayerView;

import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

final class ViewMapper {

    private static final Pattern TAGS = Pattern.compile("<[^>]+>");

    private final UUID gameId;
    private final UUID myPlayerId;
    private final Set<UUID> targets;

    ViewMapper(UUID gameId, UUID myPlayerId, Set<UUID> targets) {
        this.gameId = gameId;
        this.myPlayerId = myPlayerId;
        this.targets = targets == null ? Set.of() : targets;
    }

    JsonObject game(GameView view) {
        JsonObject o = new JsonObject();
        o.addProperty("gameId", str(gameId));
        o.addProperty("turn", view.getTurn());
        o.addProperty("phase", view.getPhase() == null ? null : view.getPhase().name());
        o.addProperty("step", view.getStep() == null ? null : view.getStep().name());
        o.addProperty("activePlayerId", str(view.getActivePlayerId()));
        o.addProperty("isPlayer", view.isPlayer());

        UUID priorityId = null;
        JsonArray players = new JsonArray();
        for (PlayerView p : view.getPlayers()) {
            if (p.hasPriority()) {
                priorityId = p.getPlayerId();
            }
            players.add(player(p, view));
        }
        o.addProperty("priorityPlayerId", str(priorityId));
        o.add("players", players);
        o.add("hand", cards(view.getMyHand(), view, null));
        o.add("stack", cards(view.getStack(), view, null));

        JsonArray combat = new JsonArray();
        for (CombatGroupView group : view.getCombat()) {
            JsonObject g = new JsonObject();
            g.add("attackerIds", ids(group.getAttackers().keySet()));
            g.add("blockerIds", ids(group.getBlockers().keySet()));
            g.addProperty("defenderId", str(group.getDefenderId()));
            g.addProperty("defenderName", group.getDefenderName());
            g.addProperty("blocked", group.isBlocked());
            combat.add(g);
        }
        o.add("combat", combat);
        return o;
    }

    JsonArray cards(CardsView cards, GameView view, UUID controllerId) {
        JsonArray a = new JsonArray();
        if (cards != null) {
            for (CardView c : cards.values()) {
                a.add(card(c, view, controllerId));
            }
        }
        return a;
    }

    private JsonObject player(PlayerView p, GameView view) {
        JsonObject o = new JsonObject();
        o.addProperty("id", str(p.getPlayerId()));
        o.addProperty("name", p.getName());
        o.addProperty("life", p.getLife());
        o.addProperty("libraryCount", p.getLibraryCount());
        o.addProperty("handCount", p.getHandCount());
        o.addProperty("isYou", p.getPlayerId().equals(myPlayerId));
        o.addProperty("isActive", p.isActive());
        o.addProperty("hasPriority", p.hasPriority());
        o.addProperty("hasLeft", p.hasLeft());
        o.addProperty("isMonarch", p.isMonarch());
        o.addProperty("choosable", targets.contains(p.getPlayerId()));

        ManaPoolView pool = p.getManaPool();
        JsonObject mana = new JsonObject();
        if (pool != null) {
            mana.addProperty("W", pool.getWhite());
            mana.addProperty("U", pool.getBlue());
            mana.addProperty("B", pool.getBlack());
            mana.addProperty("R", pool.getRed());
            mana.addProperty("G", pool.getGreen());
            mana.addProperty("C", pool.getColorless());
        }
        o.add("manaPool", mana);
        o.add("counters", counters(p.getCounters()));

        JsonArray battlefield = new JsonArray();
        for (PermanentView perm : p.getBattlefield().values()) {
            battlefield.add(card(perm, view, p.getPlayerId()));
        }
        o.add("battlefield", battlefield);
        o.add("graveyard", cards(p.getGraveyard(), view, p.getPlayerId()));
        o.add("exile", cards(p.getExile(), view, p.getPlayerId()));

        JsonArray command = new JsonArray();
        for (CommandObjectView c : p.getCommandObjectList()) {
            JsonObject co = new JsonObject();
            co.addProperty("id", str(c.getId()));
            co.addProperty("name", c.getName());
            co.addProperty("set", c.getExpansionSetCode());
            co.addProperty("number", c.getImageNumber() > 0 ? String.valueOf(c.getImageNumber()) : null);
            co.add("rules", strings(c.getRules()));
            co.addProperty("playable", isPlayable(view, c.getId()));
            co.addProperty("choosable", targets.contains(c.getId()));
            command.add(co);
        }
        o.add("command", command);
        return o;
    }

    JsonObject card(CardView c, GameView view, UUID controllerId) {
        JsonObject o = new JsonObject();
        o.addProperty("id", str(c.getId()));
        o.addProperty("name", c.isFaceDown() ? "Face-down" : c.getName());
        o.addProperty("set", c.getExpansionSetCode());
        o.addProperty("number", c.getCardNumber());
        o.addProperty("manaCost", c.getManaCostStr());
        o.addProperty("manaValue", c.getManaValue());
        o.addProperty("typeLine", c.getTypeText());
        o.add("types", strings(c.getCardTypes().stream().map(Object::toString).toList()));
        o.add("colors", colors(c.getColor()));
        o.add("rules", strings(c.getRules()));
        o.addProperty("power", emptyToNull(c.getPower()));
        o.addProperty("toughness", emptyToNull(c.getToughness()));
        o.addProperty("loyalty", emptyToNull(c.getLoyalty()));
        o.addProperty("defense", emptyToNull(c.getDefense()));
        o.addProperty("isToken", c.isToken());
        o.addProperty("isAbility", c.isAbility());
        o.addProperty("faceDown", c.isFaceDown());
        o.addProperty("rarity", c.getRarity() == null ? null : c.getRarity().getCode());
        o.add("counters", counters(c.getCounters()));
        o.addProperty("playable", isPlayable(view, c.getId()));
        o.addProperty("choosable", c.isChoosable() || targets.contains(c.getId()));
        o.addProperty("selected", c.isSelected());
        o.addProperty("controllerId", str(controllerId));
        if (c.getTargets() != null && !c.getTargets().isEmpty()) {
            o.add("targetIds", ids(c.getTargets()));
        }
        if (c instanceof PermanentView perm) {
            o.addProperty("tapped", perm.isTapped());
            o.addProperty("damage", perm.getDamage());
            o.addProperty("summoningSick", perm.hasSummoningSickness());
            o.addProperty("attachedTo", str(perm.getAttachedTo()));
            o.add("attachmentIds", ids(perm.getAttachments()));
        }
        return o;
    }

    private static boolean isPlayable(GameView view, UUID id) {
        return view != null && view.getCanPlayObjects() != null && view.getCanPlayObjects().containsObject(id);
    }

    private static JsonArray counters(List<CounterView> counters) {
        JsonArray a = new JsonArray();
        if (counters != null) {
            for (CounterView c : counters) {
                JsonObject o = new JsonObject();
                o.addProperty("name", c.getName());
                o.addProperty("count", c.getCount());
                a.add(o);
            }
        }
        return a;
    }

    private static JsonArray colors(ObjectColor color) {
        JsonArray a = new JsonArray();
        if (color != null) {
            if (color.isWhite()) a.add("W");
            if (color.isBlue()) a.add("U");
            if (color.isBlack()) a.add("B");
            if (color.isRed()) a.add("R");
            if (color.isGreen()) a.add("G");
        }
        return a;
    }

    static JsonArray strings(Collection<String> values) {
        JsonArray a = new JsonArray();
        if (values != null) {
            for (String s : values) {
                String clean = plain(s);
                if (!clean.isEmpty()) {
                    a.add(clean);
                }
            }
        }
        return a;
    }

    static String plain(String html) {
        if (html == null) {
            return "";
        }
        String s = html.replaceAll("(?i)<br\\s*/?>", "\n");
        s = TAGS.matcher(s).replaceAll("");
        return s.replace("&nbsp;", " ").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&").replace("&quot;", "\"").trim();
    }

    private static JsonArray ids(Collection<UUID> ids) {
        JsonArray a = new JsonArray();
        if (ids != null) {
            for (UUID id : ids) {
                a.add(id.toString());
            }
        }
        return a;
    }

    private static String emptyToNull(String s) {
        return s == null || s.isEmpty() ? null : s;
    }

    static String str(UUID id) {
        return id == null ? null : id.toString();
    }
}
