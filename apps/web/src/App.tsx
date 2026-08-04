import { useState } from "react";

function App() {
  const [name, setName] = useState("");
  const [companionName, setCompanionName] = useState("");
  const [started, setStarted] = useState(false);

  if (started) {
    return (
      <main className="world-shell">
        <section className="world-card">
          <div className="companion">🐱</div>
          <p className="eyebrow">Virtual Companion</p>
          <h1>{companionName || "Mimi"}</h1>
          <p className="welcome">Salom, {name}. Men seni ko‘rganimdan xursandman.</p>
          <div className="room">🏠 Bedroom · 🛏️ · 📚</div>
        </section>
      </main>
    );
  }

  return (
    <main className="onboarding-shell">
      <section className="onboarding-card">
        <div className="logo">🐱</div>
        <p className="eyebrow">Virtual Companion · v0.1</p>
        <h1>Yangi do‘st bilan tanishing</h1>
        <p className="description">
          Bu kichik dunyoda siz bilan suhbatlashadigan, sizni eslab qoladigan va
          vaqt o‘tishi bilan sizni yaxshiroq taniydigan hamroh yashaydi.
        </p>

        <label>
          Ismingiz
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="Masalan, Malika"
          />
        </label>

        <label>
          Hamrohingizning ismi
          <input
            value={companionName}
            onChange={(event) => setCompanionName(event.target.value)}
            placeholder="Masalan, Mimi"
          />
        </label>

        <button
          type="button"
          disabled={!name.trim()}
          onClick={() => setStarted(true)}
        >
          Dunyoga kirish →
        </button>
      </section>
    </main>
  );
}

export default App;
