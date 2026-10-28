import sql from 'mssql';
import {validateOperationalChange} from './operationalIntegrity.js';

export const revisionToHex = (value) => Buffer.isBuffer(value) ? `0x${value.toString('hex')}` : null;

// La revisión devuelta pertenece a ESTE guardado. El bloqueo se conserva hasta
// leerla y confirmar; una lectura posterior al COMMIT podría devolver la de otro usuario.
export async function saveStateSnapshot(pool, payload, expectedRevision, {
  transaction = new sql.Transaction(pool), request = () => new sql.Request(transaction)
} = {}) {
  let aborted = false;
  transaction.on('rollback', () => { aborted = true; });
  await transaction.begin();
  try {
    const row = (await request().query('SELECT Revision, Payload FROM dbo.ErpState WITH (UPDLOCK, HOLDLOCK) WHERE StateId = 1')).recordset[0];
    const current = row?.Revision;
    if (current && !expectedRevision) {
      throw Object.assign(new Error('Falta expectedRevision: recarga el estado antes de guardar.'), {
        status: 428, code: 'REVISION_REQUIRED', revision: revisionToHex(current)
      });
    }
    if (expectedRevision && revisionToHex(current)?.toLowerCase() !== expectedRevision.toLowerCase()) {
      throw Object.assign(new Error('Otra sesión cambió los datos. Revisa los cambios antes de volver a guardar.'), {
        status: 409, code: 'STATE_CONFLICT'
      });
    }
    validateOperationalChange(JSON.parse(payload), row?.Payload ? JSON.parse(row.Payload) : null);
    await request().input('payload', sql.NVarChar(sql.MAX), payload)
      .input('ExpectedRevision', sql.VarBinary(8), expectedRevision ? Buffer.from(expectedRevision.slice(2), 'hex') : null)
      .execute('dbo.usp_SaveErpState');
    const saved = (await request().query('SELECT Revision FROM dbo.ErpState WHERE StateId = 1')).recordset[0]?.Revision;
    if (!saved) throw new Error('SQL Server no devolvió la revisión del guardado.');
    const revision = revisionToHex(saved);
    await transaction.commit();
    return { saved: true, revision };
  } catch (error) {
    if (!aborted) await transaction.rollback();
    throw error;
  }
}
