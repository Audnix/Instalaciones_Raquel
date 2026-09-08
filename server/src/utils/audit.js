import { supabase } from "../config/supabase.js";

export async function auditLog({ userId, action, entity, entityId, before, after, ip }) {
  const payload = {
    user_id: userId,
    action,
    entity,
    entity_id: entityId,
    before_data: before ?? null,
    after_data: after ?? null,
    ip_address: ip,
    created_at: new Date().toISOString()
  };

  if (!supabase) return payload;
  await supabase.from("audit_logs").insert(payload);
  return payload;
}
