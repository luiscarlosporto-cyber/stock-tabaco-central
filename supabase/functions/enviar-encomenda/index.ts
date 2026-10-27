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
type Line = { repsol_code?: string; name: string; category: string; unit: string; qty: number; vol_size?: number | null };

// Tabaco aquecido e recargas são encomendados a outro fornecedor (segundas e quintas).
const AQUECIDO = ["Tabaco aquecido", "Cigarros eletrónicos"];
const FORNECEDOR = { tabaco: "ADELAIDE SOUSA FERREIRA", aquecido: "LOGISTA" };
const isAquecido = (lines: Line[]) => lines.length > 0 && lines.every((l) => AQUECIDO.includes(l.category));

// As fontes base do PDF só têm o alfabeto latino; troca o resto por "?".
const safe = (s: unknown) => String(s ?? "").replace(/[^\x20-\x7E -ÿ]/g, "?");

export async function buildPdf(lines: Line[], dia: string, aprovador: string, empresa: string, titulo = "Encomenda de tabaco", fornecedor = "") {
  const doc = await PDFDocument.create();
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const navy = rgb(0.07, 0.16, 0.3), grey = rgb(0.4, 0.45, 0.5);
  let page = doc.addPage([595, 842]), y = 790;
  const text = (t: string, x: number, size = 10, f = font, color = rgb(0, 0, 0)) =>
    page.drawText(safe(t), { x, y, size, font: f, color });
  const header = () => {
    text("Código Repsol", 50, 9, bold, grey); text("Produto", 140, 9, bold, grey);
    text("Quantidade", 488 - bold.widthOfTextAtSize("Quantidade", 9), 9, bold, grey); text("Unidade", 498, 9, bold, grey);
    y -= 6; page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: grey }); y -= 14;
  };
  const room = (h: number) => { if (y < 60 + h) { page = doc.addPage([595, 842]); y = 790; header(); } };
  text(titulo, 50, 20, bold, navy); y -= 22;
  if (fornecedor) { text(`Fornecedor: ${fornecedor}`, 50, 13, bold); y -= 18; }
  text(`Data: ${dia}`, 50, 11); y -= 15;
  text(`Cliente: ${empresa}`, 50, 11); y -= 15;
  text(`Aprovada por: ${aprovador}`, 50, 11); y -= 26;
  header();
  const cats = [...new Set(lines.map((l) => l.category))];
  const tot: Record<string, number> = { volumes: 0, unidades: 0 };
  for (const c of cats) {
    room(40);
    text(c, 50, 11, bold, navy); y -= 15;
    for (const l of lines.filter((l) => l.category === c)) {
      room(14);
      text(l.repsol_code || "", 50); text(l.name.slice(0, 50), 140);
      text(String(l.qty), 488 - bold.widthOfTextAtSize(String(l.qty), 10), 10, bold); text(l.unit === "volumes" && l.vol_size && l.vol_size !== 10 ? `vol. de ${l.vol_size}` : l.unit, 498); y -= 14;
      tot[l.unit] = (tot[l.unit] || 0) + l.qty;
    }
    y -= 6;
  }
  room(40); y -= 4;
  page.drawLine({ start: { x: 50, y: y + 10 }, end: { x: 545, y: y + 10 }, thickness: 0.5, color: grey });
  text(`Total: ${tot.volumes} volumes e ${tot.unidades} unidades`, 50, 11, bold); y -= 15;
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
    const { order_id } = await req.json();
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
    const pdf = await buildPdf(lines, dia, aprovador, cliente, `Encomenda de ${tipo}`, forn);
    const subject = `Encomenda ${forn} - ${comp ? comp.name + " - " : ""}${tipo} ${dia}`;
    const loja = comp ? comp.short_name.toLowerCase().replace(/\s+/g, "-") + "-" : "";
    await sendMail(para, cc, subject,
      `Bom dia,\n\nSegue em anexo a encomenda de ${tipo} de ${dia}, para ${forn}.\n\nObrigado.\n${cliente}`,
      { name: `encomenda-${loja}${aq ? "aquecido" : "tabaco"}-${dia.replaceAll("/", "-")}.pdf`, data: pdf }, comp?.gmail_suffix || "");
    const { error: e2 } = await sb.from("orders")
      .update({ status: "enviada", sent_at: new Date().toISOString(), sent_to: para, approved_by: user!.id })
      .eq("id", order_id).eq("status", "pendente");
    if (e2) return json({ ok: true, para, aviso: "Enviada, mas não ficou marcada como enviada" });
    return json({ ok: true, para });
  } catch (e) {
    return json({ ok: false, error: e instanceof Error ? e.message : "Erro no envio" }, 500);
  }
});
