import type {ErpDatabase} from '../types/erp';
export const emptyDatabase: ErpDatabase = {
 products:[],lots:[],kardex:[],sales:[],proformas:[],promotions:[],purchases:[],accounting:[],finance:[],projections:[],production:[],parties:[],employees:[],payrollRuns:[],albums:[],projects:[],cash:[],users:[],audit:[]
};
export function normalizeErpState(parsed: Partial<ErpDatabase>): ErpDatabase {
 const rows=Object.fromEntries(Object.keys(emptyDatabase).map(key=>[key,Array.isArray(parsed[key as keyof ErpDatabase])?parsed[key as keyof ErpDatabase]:[]])) as ErpDatabase;
 return {...rows,users:rows.users.map(({password:_password,...user})=>user)};
}
