export type AllocatedPayment = {
  employeeId?: string | null;
  amount: number;
  allocations?: Array<{ employeeId: string; amount: number }>;
};

// Una dispersion general tambien reduce el pendiente de cada beneficiario.
export function paidToEmployee(payments: AllocatedPayment[], employeeId: string): number {
  const total = payments.reduce((sum, payment) => {
    if (payment.allocations?.length) {
      return sum + payment.allocations.filter((a) => a.employeeId === employeeId)
        .reduce((subtotal, a) => subtotal + Number(a.amount), 0);
    }
    return sum + (payment.employeeId === employeeId ? Number(payment.amount) : 0);
  }, 0);
  return Math.round(total * 100) / 100;
}

export function pendingForEmployee(netPay: number, payments: AllocatedPayment[], employeeId: string): number {
  return Math.max(0, Math.round((Number(netPay ?? 0) - paidToEmployee(payments, employeeId)) * 100) / 100);
}
