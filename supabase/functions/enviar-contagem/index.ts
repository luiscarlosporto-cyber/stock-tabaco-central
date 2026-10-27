// Envia o ficheiro da contagem por email (Gmail da empresa ou Resend). Só aceita pedidos de utilizadores com sessão
// (o Supabase verifica o JWT antes de chegar aqui). O destinatário é fixo no servidor.
// Secrets no Supabase: GMAIL_USER + GMAIL_APP_PASSWORD (Gmail da empresa) ou RESEND_API_KEY;
// EMAIL_DESTINO (opcional).
// Duas empresas: com company_id, a contagem vai para o email dessa loja (tabela companies) e sai da conta Gmail
// dela (GMAIL_USER + gmail_suffix, ex. GMAIL_USER_PENAFIEL); só aceita lojas a que quem envia tem acesso (RLS).
import { createClient } from "jsr:@supabase/supabase-js@2";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import nodemailer from "npm:nodemailer@6.9.16";

const TO = Deno.env.get("EMAIL_DESTINO") ?? "portojoaonuneslda@gmail.com";
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ ok: false, error: "Método inválido" }, 405);
  const key = Deno.env.get("RESEND_API_KEY");
  try {
    const { csv, total, operador, correcao, company_id } = await req.json();
    if (typeof csv !== "string" || !csv.length || csv.length > 500_000) return json({ ok: false, error: "Ficheiro inválido" }, 400);
    let to = TO, suffix = "", loja = "", nomeLoja = "";
    if (company_id != null) {
      if (typeof company_id !== "string") return json({ ok: false, error: "Pedido inválido" }, 400);
      const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      });
      const { data: c } = await sb.from("companies").select("name,short_name,email_empresa,gmail_suffix").eq("id", company_id).maybeSingle();
      if (!c) return json({ ok: false, error: "Sem acesso a esta loja" }, 403);
      to = c.email_empresa || TO; suffix = c.gmail_suffix || ""; nomeLoja = c.name;
      loja = c.short_name.toLowerCase().replace(/\s+/g, "-") + "-";
    }
    const user = Deno.env.get("GMAIL_USER" + suffix), pass = Deno.env.get("GMAIL_APP_PASSWORD" + suffix);
    if (suffix && !(user && pass)) return json({ ok: false, error: `Falta configurar GMAIL_USER${suffix} e GMAIL_APP_PASSWORD${suffix}` }, 500);
    if (!key && !(user && pass)) return json({ ok: false, error: "Falta configurar o envio de email" }, 500);
    const dia = new Date().toLocaleDateString("pt-PT", { timeZone: "Europe/Lisbon" });
    const subject = `Stock tabaco ${nomeLoja ? nomeLoja + " " : ""}${dia}${correcao ? " (correção)" : ""}`;
    const nome = `stock-tabaco-${loja}${dia.replaceAll("/", "-")}${correcao ? "-correcao" : ""}.csv`;
    const body = `${subject}\nFuncionária: ${String(operador || "-").slice(0, 80)}\nTotal de unidades contadas: ${Number(total) || 0}\n\nO ficheiro segue em anexo.`;
    if (user && pass) {
      // Porta 465 (SSL): as Edge Functions não permitem ligações de saída nas portas 25 e 587.
      const t = nodemailer.createTransport({ host: "smtp.gmail.com", port: 465, secure: true, auth: { user, pass: pass.replace(/\s/g, "") } });
      await t.sendMail({ from: `NexStock <${user}>`, to, subject, text: body,
        attachments: [{ filename: nome, content: csv, contentType: "text/csv; charset=utf-8" }] });
    } else {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: "NexStock <onboarding@resend.dev>",
          to: [to],
          subject,
          text: body,
          attachments: [{ filename: nome, content: encodeBase64(new TextEncoder().encode(csv)) }],
        }),
      });
      if (!r.ok) return json({ ok: false, error: `Email recusado (${r.status})` }, 502);
    }
    return json({ ok: true });
  } catch (e) {
    return json({ ok: false, error: e instanceof SyntaxError ? "Pedido inválido" : "Falha no envio do email" }, 500);
  }
});
