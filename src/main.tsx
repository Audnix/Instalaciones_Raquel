import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { ErpProvider, useErp } from "./store/erpStore";
import "./styles.css";

const queryClient = new QueryClient();

function AuthBridge({ children }: { children: React.ReactNode }) {
  const { db } = useErp();
  return <AuthProvider directory={db.users}>{children}</AuthProvider>;
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <ErpProvider>
          <AuthBridge>
            <App />
          </AuthBridge>
        </ErpProvider>
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>
);
