import { createFileRoute } from "@tanstack/react-router";
import { useEffect } from "react";

// O app "Quadros" original (HTML/JS puro) roda a partir de /public.
const MARKUP = `
<header class="hdr">
  <a class="hdr__logo" href="#/" aria-label="Início"><img src="/assets/logo-light.png" alt="GS Infinity Travel"></a>
  <nav class="nav" aria-label="Principal">
    <a href="#/">Quadros</a>
    <a href="https://grupovilane.github.io/Geradordecota-o/" target="_blank" rel="noopener noreferrer">Gerador de Propostas</a>
    <a href="#/modelos">Modelos</a>
    <button type="button" class="nav__cta" data-act="new-board">+ Criar</button>
  </nav>
  <label class="search">
    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
    <input id="q" type="search" placeholder="Buscar cartões" autocomplete="off" aria-label="Buscar cartões">
  </label>
  <button type="button" class="out" id="out" data-act="logout" hidden aria-label="Sair da conta" title="Sair da conta"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h4M16 8l4 4-4 4M20 12H9"/></svg><span>Sair</span></button>
  <button type="button" class="me" id="me" data-act="user-menu" aria-label="Usuário e equipe"></button>
  <i class="hdr__line" aria-hidden="true"></i>
</header>
<main id="app"></main>
<dialog id="cardDlg" class="cm-dlg" aria-label="Cartão"><div class="cm" id="cm"></div></dialog>
<div id="login" class="login" hidden></div>
<div id="pop" class="pop" hidden></div>
<div id="toast" class="toast" role="status" hidden></div>
<input type="file" id="importFile" accept="application/json,.json" hidden>
`;

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Quadros | GS Infinity Travel" },
      { name: "description", content: "Quadros da operação GS Infinity Travel: listas, cartões e modelos prontos." },
      { property: "og:title", content: "Quadros | GS Infinity Travel" },
      { property: "og:description", content: "Kanban interno da GS Infinity Travel." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
      { name: "robots", content: "noindex" },
      { name: "theme-color", content: "#120D44" },
    ],
    links: [
      { rel: "icon", type: "image/png", href: "/assets/favicongs.png" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Titan+One&family=Fredoka:wght@400;500;600;700&family=Poppins:wght@300;400;500;600;700&display=swap",
      },
      { rel: "stylesheet", href: "/gs-styles.css" },
    ],
  }),
  component: Index,
});

let loaded = false;

function Index() {
  useEffect(() => {
    if (loaded) return;
    loaded = true;
    const files = ["/config.js", "/cloud.js", "/modelos.js", "/app.js"];
    (async () => {
      const [{ supabase }, { lovable }] = await Promise.all([
        import("@/integrations/supabase/client"),
        import("@/integrations/lovable/index"),
      ]);
      const w = window as unknown as Record<string, unknown>;
      w["__gsSupabase"] = supabase;
      w["__gsGoogle"] = () =>
        lovable.auth.signInWithOAuth("google", { redirect_uri: window.location.origin });
      for (const src of files) {
        await new Promise<void>((res, rej) => {
          const s = document.createElement("script");
          s.src = src;
          s.onload = () => res();
          s.onerror = () => rej(new Error(src));
          document.body.appendChild(s);
        });
      }
    })();
  }, []);

  return <div style={{ display: "contents" }} dangerouslySetInnerHTML={{ __html: MARKUP }} />;
}
