const url = process.argv[2] ?? "ws://localhost:8765/ws";
const turns = Number(process.argv[3] ?? 4);
const ws = new WebSocket(url);
const send = (o) => ws.send(JSON.stringify(o));
const counts = {};
let last;

ws.onopen = () => send({ type: "connect", username: "AutoTest" + Math.floor(Math.random() * 900 + 100) });
ws.onmessage = (event) => {
  const m = JSON.parse(event.data);
  counts[m.type] = (counts[m.type] ?? 0) + 1;
  switch (m.type) {
    case "status":
      console.log("status", m.state, m.message);
      if (m.state === "connected") send({ type: "startAIGame" });
      break;
    case "tableReady":
      console.log("table", m.deck, "vs", m.opponentDeck);
      break;
    case "game":
      last = m.state;
      if (last.turn > turns) {
        console.log(JSON.stringify(summary(last), null, 1));
        console.log("counts", counts);
        send({ type: "leaveGame" });
        setTimeout(() => process.exit(0), 500);
      }
      break;
    case "prompt": {
      const p = m.prompt;
      console.log(`T${last?.turn} ${last?.step} prompt ${p.kind}: ${p.message}`);
      if (p.kind === "select") {
        const land = last?.hand.find((c) => c.playable && c.types.includes("Land"));
        if (land) return send({ type: "respondUUID", id: land.id });
        send({ type: "respondBoolean", value: false });
      } else if (p.kind === "ask") send({ type: "respondBoolean", value: false });
      else if (p.kind === "target") {
        if (p.targetIds?.length) send({ type: "respondUUID", id: p.targetIds[0] });
        else send({ type: "respondBoolean", value: false });
      } else if (p.kind === "choice") send({ type: "respondString", value: p.choices[0].id });
      else if (p.kind === "ability") send({ type: "respondUUID", id: p.choices[0].id });
      else if (p.kind === "amount") send({ type: "respondInteger", value: p.min });
      else send({ type: "respondBoolean", value: false });
      break;
    }
    case "error":
      console.log("ERROR", m.text);
      break;
    case "gameEnd":
    case "gameOver":
      console.log(m.type, m.text ?? m.gameInfo);
      break;
  }
};
ws.onerror = (e) => console.log("ws error", e.message);

function summary(s) {
  return {
    turn: s.turn, step: s.step, hand: s.hand.map((c) => c.name),
    players: s.players.map((p) => ({
      name: p.name, life: p.life, library: p.libraryCount, hand: p.handCount,
      battlefield: p.battlefield.map((c) => `${c.name}${c.tapped ? " (T)" : ""} [${c.set}:${c.number}]`),
    })),
  };
}
