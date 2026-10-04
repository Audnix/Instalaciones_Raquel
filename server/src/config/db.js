import pg from "pg";

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL;

export const pool = connectionString
  ? new Pool({ connectionString, max: 10 })
  : null;

export async function pingDb() {
  if (!pool) throw new Error("DATABASE_URL no esta configurada.");
  const result = await pool.query("SELECT current_database() AS db, current_user AS usr, NOW() AS at");
  return result.rows[0];
}
