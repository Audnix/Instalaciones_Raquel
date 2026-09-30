import pg from "pg";

const { Pool } = pg;

const connectionString =
  process.env.DATABASE_URL ?? "postgres://raquel:raquel2026@127.0.0.1:5432/instalaciones_raquel";

export const pool = new Pool({
  connectionString,
  max: 10
});

export async function pingDb() {
  const result = await pool.query("SELECT current_database() AS db, current_user AS usr, NOW() AS at");
  return result.rows[0];
}
