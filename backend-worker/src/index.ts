import { Client } from "pg";
interface Env { HYPERDRIVE: Hyperdrive; BACKEND_API_URL?: string; }
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS", "Access-Control-Allow-Headers": "Content-Type, Authorization", "Content-Type": "application/json; charset=utf-8" };
const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: cors });
async function db<T>(env: Env, fn: (c: Client) => Promise<T>): Promise<T> {
  const c = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  try { await c.connect(); return await fn(c); } finally { await c.end().catch(() => undefined); }
}
export default {
 async fetch(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url), path = url.pathname;
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  const backendRoute = /^\/api\/v1\/(auth|bookings|provider\/me)(\/|$)/.test(path);
  if (backendRoute) {
   if (!env.BACKEND_API_URL) return json({ success: false, message: "Backend API belum dikonfigurasi" }, 503);
   try {
    const origin = env.BACKEND_API_URL.replace(/\/$/, "");
    const upstreamUrl = new URL(origin + path + url.search);
    const upstream = await fetch(new Request(upstreamUrl.toString(), request));
    const headers = new Headers(upstream.headers);
    for (const [key, value] of Object.entries(cors)) headers.set(key, value);
    return new Response(upstream.body, { status: upstream.status, statusText: upstream.statusText, headers });
   } catch (e) {
    console.error("Backend proxy failed", e);
    return json({ success: false, message: "Backend API tidak dapat dihubungi" }, 502);
   }
  }
  if (request.method !== "GET") return json({ success: false, message: "Method not allowed" }, 405);
  if (path === "/" || path === "/health" || path === "/api/health") return json({ success: true, service: "yuku-api-worker", status: "ok" });
  if (path === "/health/db" || path === "/api/health/db") {
   try {
    const r = await db(env, c => c.query("SELECT current_database() AS database, NOW() AS server_time"));
    return json({ success: true, service: "yuku-api-worker", database: "connected", databaseName: r.rows[0]?.database, checkedAt: r.rows[0]?.server_time });
   } catch (e) { console.error("DB health failed", e); return json({ success: false, database: "disconnected", message: "Database connection failed" }, 503); }
  }
  if (path === "/api/v1/categories") {
   try {
    const r = await db(env, c => c.query('SELECT "id", "name", "slug", "pillar", "parentId" FROM "Category" WHERE "isActive" = TRUE ORDER BY "pillar", "name"'));
    return json({ success: true, data: r.rows });
   } catch (e) { console.error("Categories query failed", e); return json({ success: false, message: "Unable to load categories" }, 503); }
  }
  if (path === "/api/v1/services") {
   const q=(url.searchParams.get("q")||"").trim().slice(0,100), category=(url.searchParams.get("category")||"").trim().slice(0,80), pillar=(url.searchParams.get("pillar")||"").trim().slice(0,40), city=(url.searchParams.get("city")||"").trim().slice(0,80), limit=Math.min(Math.max(Number(url.searchParams.get("limit")||20),1),50);
   try {
    const r = await db(env, c => c.query(`SELECT s."id",s."title",s."description",s."mode",s."priceAmount",s."currency",s."priceUnit",s."durationMinutes",s."city",s."province",c."name" AS "categoryName",c."slug" AS "categorySlug",c."pillar",p."verificationStatus",p."averageRating",p."reviewCount",pr."displayName" AS "providerName",pr."avatarUrl" AS "providerAvatar"
     FROM "Service" s JOIN "Category" c ON c."id"=s."categoryId" JOIN "ProviderProfile" p ON p."id"=s."providerId" JOIN "User" u ON u."id"=p."userId" LEFT JOIN "Profile" pr ON pr."userId"=u."id"
     WHERE s."isPublished"=TRUE AND u."status"='ACTIVE' AND ($1='' OR s."title" ILIKE '%'||$1||'%' OR s."description" ILIKE '%'||$1||'%') AND ($2='' OR c."slug"=$2) AND ($3='' OR c."pillar"=$3) AND ($4='' OR s."city" ILIKE '%'||$4||'%')
     ORDER BY (p."verificationStatus"='VERIFIED') DESC,p."averageRating" DESC NULLS LAST,s."createdAt" DESC LIMIT $5`,[q,category,pillar,city,limit]));
    return json({ success:true, count:r.rowCount, data:r.rows });
   } catch(e) { console.error("Services query failed",e); return json({ success:false,message:"Unable to load services" },503); }
  }
  const m=path.match(/^\/api\/v1\/services\/([0-9a-f-]{36})$/i);
  if (m) {
   try {
    const r=await db(env,c=>c.query(`SELECT s."id",s."title",s."description",s."mode",s."priceAmount",s."currency",s."priceUnit",s."durationMinutes",s."city",s."province",c."name" AS "categoryName",c."slug" AS "categorySlug",c."pillar",p."verificationStatus",p."averageRating",p."reviewCount",p."experienceYears",p."languages",pr."displayName" AS "providerName",pr."avatarUrl" AS "providerAvatar",pr."bio" AS "providerBio"
     FROM "Service" s JOIN "Category" c ON c."id"=s."categoryId" JOIN "ProviderProfile" p ON p."id"=s."providerId" JOIN "User" u ON u."id"=p."userId" LEFT JOIN "Profile" pr ON pr."userId"=u."id"
     WHERE s."id"=$1 AND s."isPublished"=TRUE AND u."status"='ACTIVE' LIMIT 1`,[m[1]]));
    if(!r.rows[0]) return json({success:false,message:"Service not found"},404);
    return json({success:true,data:r.rows[0]});
   } catch(e) { console.error("Service detail query failed",e); return json({success:false,message:"Unable to load service"},503); }
  }
  return json({ success:false,message:"Not found" },404);
 }
} satisfies ExportedHandler<Env>;
