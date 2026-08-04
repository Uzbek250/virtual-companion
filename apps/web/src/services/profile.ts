import { supabase } from "../lib/supabase";

export interface ProfileInput {
  name: string;
}

export async function getProfile(userId: string) {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") {
      return null;
    }
    throw error;
  }

  return data;
}

export async function createProfile(userId: string, input: ProfileInput) {
  const { data, error } = await supabase
    .from("profiles")
    .insert({
      id: userId,
      name: input.name,
      onboarding_completed: true,
    })
    .select()
    .single();

  if (error) {
    throw error;
  }

  return data;
}

export async function updateLastSeen(userId: string) {
  const { error } = await supabase
    .from("profiles")
    .update({
      last_seen_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (error) {
    throw error;
  }
}
