import { ButtonHTMLAttributes, ReactNode } from "react";
import { clsx } from "clsx";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  icon?: ReactNode;
};

export function Button({ className, variant = "primary", icon, children, ...props }: ButtonProps) {
  return (
    <button
      className={clsx(
        "ripple inline-flex min-h-10 items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60",
        variant === "primary" && "bg-brand-600 text-white shadow-lg shadow-brand-600/20 hover:bg-brand-700",
        variant === "secondary" && "border border-slate-200 bg-white text-slate-700 hover:border-brand-200 hover:text-brand-700 dark:border-white/10 dark:bg-white/10 dark:text-slate-100",
        variant === "ghost" && "text-slate-600 hover:bg-slate-100 dark:text-slate-200 dark:hover:bg-white/10",
        variant === "danger" && "bg-ember text-white shadow-lg shadow-rose-500/20 hover:bg-rose-600",
        className
      )}
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}
