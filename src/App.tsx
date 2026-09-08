import { lazy, Suspense, useCallback, useEffect, useState } from "react";
import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { useAuth } from "./auth/AuthContext";
import { Loader } from "./components/Loader";
import { SplashScreen } from "./components/SplashScreen";
import { AppShell } from "./layouts/AppShell";
import { ensurePublicOrigin } from "./lib/publicOrigin";

const Login = lazy(() => import("./pages/Login"));
const Dashboard = lazy(() => import("./pages/Dashboard"));
const ModulePage = lazy(() => import("./pages/ModulePage"));
const ValidateInvoicePage = lazy(() => import("./pages/ValidateInvoicePage"));

export default function App() {
  const { isAuthenticated, logout } = useAuth();
  const location = useLocation();
  const isValidate = location.pathname.startsWith("/validar");
  const [dark, setDark] = useState(() => localStorage.getItem("raquel_theme") === "dark");
  const [showSplash, setShowSplash] = useState(() => {
    if (typeof window !== "undefined" && window.location.pathname.startsWith("/validar")) return false;
    return sessionStorage.getItem("raquel_splash_done") !== "1";
  });

  const finishSplash = useCallback(() => {
    sessionStorage.setItem("raquel_splash_done", "1");
    setShowSplash(false);
  }, []);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", dark);
    localStorage.setItem("raquel_theme", dark ? "dark" : "light");
  }, [dark]);

  useEffect(() => {
    void ensurePublicOrigin().then(() => {
      window.dispatchEvent(new Event("raquel-origin-ready"));
    });
  }, []);

  if (isValidate) {
    return (
      <Suspense fallback={<Loader label="Abriendo factura" />}>
        <ValidateInvoicePage />
      </Suspense>
    );
  }

  return (
    <>
      <AnimatePresence>{showSplash && <SplashScreen onDone={finishSplash} />}</AnimatePresence>
      {!showSplash && (
        <AnimatePresence mode="wait">
          <Suspense fallback={<Loader label="Cargando" />}>
            <Routes>
              <Route
                path="/login"
                element={
                  isAuthenticated ? (
                    <Navigate to="/" replace />
                  ) : (
                    <motion.div key="login" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                      <Login dark={dark} toggleTheme={() => setDark((value) => !value)} />
                    </motion.div>
                  )
                }
              />
              <Route
                path="/*"
                element={
                  isAuthenticated ? (
                    <AppShell onLogout={logout} dark={dark} toggleTheme={() => setDark((value) => !value)}>
                      <Routes>
                        <Route index element={<Dashboard />} />
                        <Route path=":moduleId" element={<ModulePage />} />
                      </Routes>
                    </AppShell>
                  ) : (
                    <Navigate to="/login" replace />
                  )
                }
              />
            </Routes>
          </Suspense>
        </AnimatePresence>
      )}
    </>
  );
}
