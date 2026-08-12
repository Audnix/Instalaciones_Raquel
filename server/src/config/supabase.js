import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

export const supabase = url && serviceKey ? createClient(url, serviceKey, { auth: { persistSession: false } }) : null;
export const supabaseAuth = url && anonKey ? createClient(url, anonKey, { auth: { persistSession: false } }) : null;
