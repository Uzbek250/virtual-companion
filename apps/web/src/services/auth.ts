import { supabase } from '../lib/supabase';

export async function signInAnonymous() {
  const { data, error } = await supabase.auth.signInAnonymously();

  if (error) throw error;

  return data.user;
}

export async function getUser() {
  const { data } = await supabase.auth.getUser();
  return data.user;
}
