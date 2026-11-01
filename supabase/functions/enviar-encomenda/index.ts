// Envia ao fornecedor, em PDF, uma proposta de encomenda aprovada por um administrador.
// Usa a sessão de quem chama: só um administrador consegue ler, aprovar e marcar a encomenda (RLS).
// Secrets no Supabase:
//   EMAIL_FORNECEDOR (obrigatório)  destinatário da encomenda de tabaco
//   EMAIL_FORNECEDOR_AQUECIDO (opcional) destinatário da encomenda de tabaco aquecido e recargas;
//                                    sem ele, vai para EMAIL_FORNECEDOR
//   EMAIL_EMPRESA    (opcional)     recebe cópia; por defeito portojoaonuneslda@gmail.com
//   GMAIL_USER + GMAIL_APP_PASSWORD envio pelo Gmail da empresa (recomendado)
//   ou RESEND_API_KEY               envio pelo Resend (só chega a outros emails com domínio verificado)
// Duas empresas: a tabela companies (supabase_empresas.sql) dá, por loja, o nome do cliente, a cópia, os emails dos
// fornecedores e o sufixo dos secrets do Gmail. Penafiel envia com GMAIL_USER_PENAFIEL + GMAIL_APP_PASSWORD_PENAFIEL
// e nunca pela conta de Santo Tirso.
// Com { preview: true } devolve o PDF em base64 para ser visto antes da aprovação, sem enviar nada.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { PDFDocument, StandardFonts, rgb } from "npm:pdf-lib@1.17.1";
import nodemailer from "npm:nodemailer@6.9.16";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

type Company = { id: string; name: string; short_name: string; email_empresa: string; email_tabaco: string; email_aquecido: string; gmail_suffix: string };
type Line = { repsol_code?: string; name: string; category: string; unit: string; qty: number; vol_size?: number | null; livre?: boolean };

// Tabaco aquecido e recargas são encomendados a outro fornecedor (segundas e quintas).
const AQUECIDO = ["Tabaco aquecido", "Cigarros eletrónicos"];
const FORNECEDOR = { tabaco: "ADELAIDE SOUSA FERREIRA", aquecido: "LOGISTA" };
// Referências livres ("Outras referências") não decidem o fornecedor.
const isAquecido = (lines: Line[]) => { const c = lines.filter((l) => l.category !== "Outras referências"); return c.length > 0 && c.every((l) => AQUECIDO.includes(l.category)); };

// As fontes base do PDF só têm o alfabeto latino; troca o resto por "?".
const safe = (s: unknown) => String(s ?? "").replace(/[^\x20-\x7E\xA0-\xFF]/g, "?");

const CAT_ORD = ["Cigarros", "Onças", "Latas", "Sacos", "Cigarrilhas", "Tabaco aquecido", "Cigarros eletrónicos"];
const catOrd = (c: string) => { const k = CAT_ORD.indexOf(c); return k < 0 ? 99 : k; };
const UND: Record<string, string> = { Latas: "latas", Sacos: "sacos" };
// Resumo por categoria: "12 volumes", "5 LATAS", "2 volumes + 3 UNIDADES".
export function resumo(lines: Line[]) {
  const m: Record<string, { cat: string; vol: number; un: number }> = {};
  for (const l of lines) { const c = l.category || "Outros"; const r = m[c] ??= { cat: c, vol: 0, un: 0 }; if (l.unit === "volumes") r.vol += l.qty; else r.un += l.qty; }
  return Object.values(m).sort((a, b) => catOrd(a.cat) - catOrd(b.cat) || a.cat.localeCompare(b.cat, "pt")).map((r) => {
    const p: string[] = [], u = UND[r.cat] || "unidades";
    if (r.vol) p.push(`${r.vol} ${r.vol === 1 ? "volume" : "volumes"}`);
    if (r.un) p.push(`${r.un} ${(r.un === 1 ? u.replace(/s$/, "") : u).toUpperCase()}`);
    return { cat: r.cat, unidades: !r.vol, txt: p.join(" + ") };
  });
}

export async function buildPdf(lines: Line[], dia: string, aprovador: string, empresa: string, titulo = "Encomenda de tabaco", fornecedor = "", notas = "") {
  const doc = await PDFDocument.create();
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const navy = rgb(0.07, 0.16, 0.3), grey = rgb(0.4, 0.45, 0.5), laranja = rgb(0.76, 0.25, 0.05), fundoUn = rgb(1, 0.95, 0.9);
  let page = doc.addPage([595, 842]), y = 790;
  const text = (t: string, x: number, size = 10, f = font, color = rgb(0, 0, 0)) =>
    page.drawText(safe(t), { x, y, size, font: f, color });
  const right = (t: string, xr: number, size = 10, f = font, color = rgb(0, 0, 0)) => text(t, xr - f.widthOfTextAtSize(safe(t), size), size, f, color);
  const header = () => {
    text("Código Repsol", 50, 9, bold, grey); text("Produto", 140, 9, bold, grey);
    right("Quantidade", 488, 9, bold, grey); text("Unidade", 498, 9, bold, grey);
    y -= 6; page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: grey }); y -= 14;
  };
  const room = (h: number, cab = true) => { if (y < 60 + h) { page = doc.addPage([595, 842]); y = 790; if (cab) header(); } };
  const linhasTexto = (t: string, max: number, size: number) => {
    const out: string[] = [];
    for (const par of String(t).split(/\r?\n/).map(safe)) {
      let cur = "";
      for (const w of par.split(/\s+/)) { const n = cur ? cur + " " + w : w; if (font.widthOfTextAtSize(n, size) > max && cur) { out.push(cur); cur = w; } else cur = n; }
      out.push(cur);
    }
    return out;
  };
  text(titulo, 50, 20, bold, navy); y -= 22;
  if (fornecedor) { text(`Fornecedor: ${fornecedor}`, 50, 13, bold); y -= 18; }
  text(`Data: ${dia}`, 50, 11); y -= 15;
  text(`Cliente: ${empresa}`, 50, 11); y -= 15;
  text(`Aprovada por: ${aprovador}`, 50, 11); y -= 22;
  // Resumo por categoria
  const res = resumo(lines);
  const hRes = 22 + res.length * 15;
  page.drawRectangle({ x: 50, y: y - hRes + 14, width: 495, height: hRes, color: rgb(0.95, 0.96, 0.98), borderColor: grey, borderWidth: 0.5 });
  text("RESUMO", 60, 10, bold, navy); y -= 17;
  for (const r of res) { text(r.cat, 60, 11); right(r.txt, 535, 11, bold, r.unidades ? laranja : rgb(0, 0, 0)); y -= 15; }
  y -= 16;
  header();
  const cats = [...new Set(lines.map((l) => l.category || "Outros"))].sort((a, b) => catOrd(a) - catOrd(b) || a.localeCompare(b, "pt"));
  const tot: Record<string, number> = { volumes: 0, unidades: 0 };
  for (const c of cats) {
    const ls = lines.filter((l) => (l.category || "Outros") === c), soUn = ls.every((l) => l.unit !== "volumes");
    room(44);
    text(c, 50, 11, bold, soUn ? laranja : navy);
    if (soUn) text("(ENCOMENDA À UNIDADE)", 60 + bold.widthOfTextAtSize(safe(c), 11), 9, bold, laranja);
    y -= 15;
    for (const l of ls) {
      room(14);
      const un = l.unit !== "volumes";
      if (un) page.drawRectangle({ x: 48, y: y - 4, width: 499, height: 14, color: fundoUn });
      text(l.repsol_code || "", 50); text(l.name.slice(0, 50), 140);
      right(String(l.qty), 488, 10, bold, un ? laranja : rgb(0, 0, 0));
      if (un) text("UNIDADES", 498, 9, bold, laranja);
      else text(l.vol_size && l.vol_size !== 10 ? `vol. de ${l.vol_size}` : "volumes", 498);
      y -= 14;
      tot[un ? "unidades" : "volumes"] += l.qty;
    }
    y -= 6;
  }
  room(40, false); y -= 4;
  page.drawLine({ start: { x: 50, y: y + 10 }, end: { x: 545, y: y + 10 }, thickness: 0.5, color: grey });
  text(`Total: ${tot.volumes} volumes e ${tot.unidades} unidades`, 50, 11, bold); y -= 15;
  if (notas.trim()) {
    const ls = linhasTexto(notas.trim(), 475, 10);
    room(30 + ls.length * 13, false); y -= 12;
    text("OBSERVAÇÕES", 50, 10, bold, navy); y -= 15;
    for (const l of ls) { room(14, false); text(l, 60, 10); y -= 13; }
  }
  return await doc.save();
}

async function sendMail(to: string, cc: string, subject: string, body: string, file: { name: string; data: Uint8Array }, suffix = "") {
  const user = Deno.env.get("GMAIL_USER" + suffix), pass = Deno.env.get("GMAIL_APP_PASSWORD" + suffix);
  if (suffix && !(user && pass)) throw new Error(`Falta configurar GMAIL_USER${suffix} e GMAIL_APP_PASSWORD${suffix}`);
  if (user && pass) {
    // Porta 465 (SSL): as Edge Functions não permitem ligações de saída nas portas 25 e 587.
    const t = nodemailer.createTransport({ host: "smtp.gmail.com", port: 465, secure: true, auth: { user, pass: pass.replace(/\s/g, "") } });
    await t.sendMail({ from: `NexStock <${user}>`, to, cc: cc || undefined, subject, text: body,
      attachments: [{ filename: file.name, content: file.data, contentType: "application/pdf" }] });
    return;
  }
  const key = Deno.env.get("RESEND_API_KEY");
  if (!key) throw new Error("Falta configurar o envio de email (GMAIL_USER e GMAIL_APP_PASSWORD)");
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: "NexStock <onboarding@resend.dev>", to: [to], cc: cc ? [cc] : undefined, subject, text: body,
      attachments: [{ filename: file.name, content: encodeBase64(file.data) }] }),
  });
  if (!r.ok) throw new Error(`Email recusado (${r.status})`);
}

if (import.meta.main) Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ ok: false, error: "Método inválido" }, 405);
  const to = Deno.env.get("EMAIL_FORNECEDOR") ?? "";
  const empresa = Deno.env.get("EMAIL_EMPRESA") ?? "portojoaonuneslda@gmail.com";
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  try {
    const { order_id, preview } = await req.json();
    if (typeof order_id !== "string") return json({ ok: false, error: "Pedido inválido" }, 400);
    const { data: isAdmin } = await sb.rpc("is_admin");
    if (isAdmin !== true) return json({ ok: false, error: "Só um administrador pode aprovar encomendas" }, 403);
    const { data: { user } } = await sb.auth.getUser();
    const { data: prof } = await sb.from("profiles").select("display_name").eq("user_id", user!.id).maybeSingle();
    const { data: o, error } = await sb.from("orders").select("*").eq("id", order_id).maybeSingle();
    if (error || !o) return json({ ok: false, error: "Encomenda não encontrada" }, 404);
    if (o.status !== "pendente") return json({ ok: false, error: "Esta encomenda já foi " + o.status }, 409);
    const lines = (o.lines as Line[]).filter((l) => Number.isInteger(l.qty) && l.qty > 0);
    if (!lines.length) return json({ ok: false, error: "A encomenda está vazia" }, 400);
    const dia = new Date().toLocaleDateString("pt-PT", { timeZone: "Europe/Lisbon" });
    const aprovador = prof?.display_name || user!.email || "administrador";
    let comp: Company | null = null;
    if (o.company_id) {
      const { data: c } = await sb.from("companies").select("*").eq("id", o.company_id).maybeSingle();
      if (!c) return json({ ok: false, error: "Loja da encomenda não encontrada" }, 404);
      comp = c as Company;
    }
    const aq = isAquecido(lines);
    const para = aq ? comp?.email_aquecido || Deno.env.get("EMAIL_FORNECEDOR_AQUECIDO") || to : comp?.email_tabaco || to;
    if (!para) return json({ ok: false, error: "Falta configurar EMAIL_FORNECEDOR" }, 500);
    const cc = comp?.email_empresa || empresa, cliente = comp?.name || empresa;
    const tipo = aq ? "tabaco aquecido e recargas" : "tabaco convencional";
    const forn = aq ? FORNECEDOR.aquecido : FORNECEDOR.tabaco;
    const notas = String(o.notes ?? "").slice(0, 1000);
    const pdf = await buildPdf(lines, dia, aprovador, cliente, `Encomenda de ${tipo}`, forn, notas);
    const subject = `Encomenda ${forn} - ${comp ? comp.name + " - " : ""}${tipo} ${dia}`;
    const loja = comp ? comp.short_name.toLowerCase().replace(/\s+/g, "-") + "-" : "";
    const ficheiro = `encomenda-${loja}${aq ? "aquecido" : "tabaco"}-${dia.replaceAll("/", "-")}.pdf`;
    // Pré-visualização (31/10/2026): devolve o PDF exatamente como seria enviado, sem enviar nem marcar a encomenda.
    if (preview === true) return json({ ok: true, preview: true, para, fornecedor: forn, ficheiro, pdf: encodeBase64(pdf) });
    await sendMail(para, cc, subject,
      `Bom dia,\n\nSegue em anexo a encomenda de ${tipo} de ${dia}, para ${forn}.\n\nResumo:\n${resumo(lines).map((r) => `- ${r.cat}: ${r.txt}`).join("\n")}${notas.trim() ? `\n\nObservações:\n${notas.trim()}` : ""}\n\nObrigado.\n${cliente}`,
      { name: ficheiro, data: pdf }, comp?.gmail_suffix || "");
    const { error: e2 } = await sb.from("orders")
      .update({ status: "enviada", sent_at: new Date().toISOString(), sent_to: para, approved_by: user!.id })
      .eq("id", order_id).eq("status", "pendente");
    if (e2) return json({ ok: true, para, aviso: "Enviada, mas não ficou marcada como enviada" });
    return json({ ok: true, para });
  } catch (e) {
    return json({ ok: false, error: e instanceof Error ? e.message : "Erro no envio" }, 500);
  }
});
