export type CompanionSpecies = "cat";

export type CompanionActivity =
  | "idle"
  | "sleeping"
  | "walking"
  | "talking"
  | "reading";

export interface UserProfile {
  id: string;
  name: string;
  createdAt: string;
  lastSeenAt: string;
  onboardingCompleted: boolean;
}

export interface Companion {
  id: string;
  userId: string;
  name: string;
  species: CompanionSpecies;
  mood: string;
  energy: number;
  currentRoom: string;
  currentActivity: CompanionActivity;
}
