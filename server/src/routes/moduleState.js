import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { getDatabase } from '../config/sqlserver.js';
import { revisionToHex, saveStateSnapshot } from '../services/stateSnapshot.js';
import { authorizeModule, mergeModuleState, projectModuleState } from '../services/moduleState.js';
import { readProductionSource } from '../services/productionSource.js';

export const moduleStateRouter = Router();
moduleStateRouter.use(requireAuth);
const schema = z.object({ state: z.record(z.array(z.record(z.unknown()))), expectedRevision: z.string().regex(/^0x[0-9a-f]{16}$/i) }).strict();

moduleStateRouter.get('/:module/source', authorizeModule, async(req,res,next)=>{
 try{
  if(req.params.module!=='produccion')return res.status(404).json({message:'Origen no disponible para este módulo.'});
  const parsed=z.string().trim().min(1).max(80).safeParse(req.query.invoice);
  if(!parsed.success)return res.status(400).json({message:'Indica un número de factura válido.'});
  const pool=await getDatabase();
  if(!pool)return res.status(503).json({message:'SQL Server no está disponible.'});
  const source=await readProductionSource(()=>pool.request(),parsed.data);
  if(!source)return res.status(404).json({message:'No se encontró una factura confirmada con detalle para preparar la orden.'});
  res.json(source);
 }catch(error){next(error);}
});

moduleStateRouter.get('/:module', authorizeModule, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: 'SQL Server no está configurado.' });
    const row = (await pool.request().query('SELECT Payload, Revision FROM dbo.ErpState WHERE StateId=1')).recordset[0];
    if (!row?.Payload) return res.status(503).json({ message: 'El área no tiene datos SQL disponibles.' });
    res.json({ state: projectModuleState(JSON.parse(row.Payload), req.params.module), revision: revisionToHex(row.Revision) });
  } catch (error) { next(error); }
});

moduleStateRouter.put('/:module', authorizeModule, async (req, res, next) => {
  try {
    const data = schema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: 'SQL Server no está configurado.' });
    res.json(await saveStateSnapshot(pool, JSON.stringify(data.state), data.expectedRevision, {
      transform: (incoming, previous) => mergeModuleState(incoming, previous, req.params.module, req.user)
    }));
  } catch (error) { next(error); }
});
