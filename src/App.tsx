import { lazy, Suspense, useEffect, useMemo, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { AppShell } from "./layouts/AppShell";
import { Loader } from "./components/Loader";

const Login = lazy(() => import("./pages/Login"));
const Dashboard = lazy(() => import("./pages/Dashboard"));
const ModulePage = lazy(() => import("./pages/ModulePage"));

export default function App() {
  const [isAuthed, setIsAuthed] = useState(() => localStorage.getItem("raquel_session") === "active");
  const [dark, setDark] = useState(() => localStorage.getItem("raquel_theme") === "dark");

  useEffect(() => {
    document.documentElement.classList.toggle("dark", dark);
    localStorage.setItem("raquel_theme", dark ? "dark" : "light");
  }, [dark]);

  const auth = useMemo(
    () => ({
      isAuthed,
      login: () => {
        localStorage.setItem("raquel_session", "active");
        setIsAuthed(true);
      },
      logout: () => {
        localStorage.removeItem("raquel_session");
        setIsAuthed(false);
      },
      dark,
      toggleTheme: () => setDark((value) => !value)
    }),
    [dark, isAuthed]
  );

  return (
    <AnimatePresence mode="wait">
      <Suspense fallback={<Loader label="Preparando ERP" />}>
        <Routes>
          <Route
            path="/login"
            element={
              isAuthed ? (
                <Navigate to="/" replace />
              ) : (
                <motion.div key="login" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                  <Login onLogin={auth.login} dark={dark} toggleTheme={auth.toggleTheme} />
                </motion.div>
              )
            }
          />
          <Route
            path="/*"
            element={
              isAuthed ? (
                <AppShell onLogout={auth.logout} dark={dark} toggleTheme={auth.toggleTheme}>
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
  );
}
