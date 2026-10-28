import test from 'node:test';
import assert from 'node:assert/strict';
import {canManagePayrollMoney,requiresPayrollFinancialPermission} from '../src/services/payrollPermissions.js';
test('preparar nomina no concede permiso para pagar o aprobar fondos',()=>{
  assert.equal(canManagePayrollMoney({hierarchy:'administrador',areas:['rrhh']}),false);
  assert.equal(canManagePayrollMoney({hierarchy:'administrador',areas:['ventas']}),false);
  for(const hierarchy of ['estandar','invitado'])assert.equal(canManagePayrollMoney({hierarchy,areas:['finanzas','contabilidad']}),false);
  for(const area of ['finanzas','contabilidad'])assert.equal(canManagePayrollMoney({hierarchy:'administrador',areas:[area]}),true);
  assert.equal(canManagePayrollMoney({hierarchy:'superadmin',areas:[]}),true);
});
test('las transiciones financieras requieren permiso en la API',()=>{
  for(const status of ['aprobada','pago_registrado','conciliada','cerrada'])assert.equal(requiresPayrollFinancialPermission(status),true);
  for(const status of ['borrador','calculada','revisada'])assert.equal(requiresPayrollFinancialPermission(status),false);
});
