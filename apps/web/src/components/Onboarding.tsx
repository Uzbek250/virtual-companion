import { useState } from "react";

interface OnboardingProps {
  onComplete: (name: string) => Promise<void>;
}

export default function Onboarding({ onComplete }: OnboardingProps) {
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();

    if (!name.trim()) return;

    setLoading(true);
    try {
      await onComplete(name.trim());
    } finally {
      setLoading(false);
    }
  }

  return (
    <main>
      <h1>🐱 Salom, yangi do‘stim</h1>
      <p>Avval ismingni bilib olay.</p>

      <form onSubmit={handleSubmit}>
        <input
          value={name}
          onChange={(event) => setName(event.target.value)}
          placeholder="Ismingiz"
        />

        <button disabled={loading} type="submit">
          {loading ? "Saqlanmoqda..." : "Boshlash"}
        </button>
      </form>
    </main>
  );
}
