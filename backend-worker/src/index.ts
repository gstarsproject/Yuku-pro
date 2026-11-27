import { Client } from "pg";
interface Env { HYPERDRIVE: Hyperdrive; }
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST, OPTIONS", "Access-Control-Allow-Headers": "Content-Type, Authorization", "Content-Type": "application/json; charset=utf-8" };
const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: cors });
async function db<T>(env: Env, fn: (c: Client) => Promise<T>): Promise<T> {
  const c = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  try { await c.connect(); return await fn(c); } finally { await c.end().catch(() => undefined); }
}

const TOKEN_TTL_SECONDS = 28800;
const encoder = new TextEncoder();
const toHex = (bytes: Uint8Array) => Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("");
async function sha256(value: string) {
  return toHex(new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(value))));
}
const PASSWORD_HASH_ITERATIONS = 100000; // Cloudflare Workers WebCrypto supports at most 100,000 PBKDF2 iterations.
async function makePasswordHash(password: string) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
  const bits = new Uint8Array(await crypto.subtle.deriveBits({ name: "PBKDF2", salt, iterations: PASSWORD_HASH_ITERATIONS, hash: "SHA-256" }, key, 256));
  return "pbkdf2$" + PASSWORD_HASH_ITERATIONS + "$" + toHex(salt) + "$" + toHex(bits);
}
async function checkPassword(password: string, stored: string) {
  const parts = stored.split("$");
  if (parts.length !== 4 || parts[0] !== "pbkdf2" || Number(parts[1]) !== PASSWORD_HASH_ITERATIONS ||
      !/^[a-f0-9]{32}$/i.test(parts[2]) || !/^[a-f0-9]{64}$/i.test(parts[3])) return false;
  const salt = new Uint8Array(parts[2].match(/../g)!.map(v => parseInt(v, 16)));
  const key = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
  const bits = new Uint8Array(await crypto.subtle.deriveBits({ name: "PBKDF2", salt, iterations: Number(parts[1]), hash: "SHA-256" }, key, 256));
  const actual = toHex(bits), expected = parts[3].toLowerCase();
  if (actual.length !== expected.length) return false;
  let mismatch = 0;
  for (let i = 0; i < actual.length; i++) mismatch |= actual.charCodeAt(i) ^ expected.charCodeAt(i);
  return mismatch === 0;
}
async function createUserSession(c: Client, user: {id:string;email:string;role:string;displayName:string|null}) {
  const token = crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "");
  const tokenHash = await sha256(token);
  await c.query('INSERT INTO "UserSession" ("id","userId","tokenHash","expiresAt") VALUES ($1,$2,$3,NOW() + INTERVAL \'8 hours\')',
    [crypto.randomUUID(), user.id, tokenHash]);
  return { accessToken: token, tokenType: "Bearer", expiresIn: TOKEN_TTL_SECONDS, user };
}
async function readRequestBody(request: Request) {
  const size = Number(request.headers.get("content-length") || 0);
  if (size > 8192) throw new Error("Payload too large");
  return await request.json() as Record<string, unknown>;
}
async function getSessionUser(c: Client, request: Request) {
  const header = request.headers.get("authorization") || "";
  if (!header.startsWith("Bearer ")) return null;
  const token = header.slice(7).trim();
  if (!/^[a-f0-9]{64}$/i.test(token)) return null;
  const tokenHash = await sha256(token);
  const result = await c.query(
    'SELECT u."id",u."email",u."phone",u."role",p."displayName",p."avatarUrl",p."bio",p."city",p."province",u."createdAt" FROM "UserSession" s JOIN "User" u ON u."id"=s."userId" LEFT JOIN "Profile" p ON p."userId"=u."id" WHERE s."tokenHash"=$1 AND s."expiresAt">NOW() AND u."status"=\'ACTIVE\' AND u."role"<>\'ADMIN\' LIMIT 1',
    [tokenHash]);
  return result.rows[0] || null;
}

export default {
 async fetch(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url), path = url.pathname;
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

  if (path === "/api/v1/auth/register" && request.method === "POST") {
   try {
    const body = await readRequestBody(request);
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const displayName = typeof body.displayName === "string" ? body.displayName.trim() : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 10 || password.length > 128 || displayName.length < 2 || displayName.length > 40)
      return json({success:false,message:"Email, password (10–128 karakter), atau nama tidak valid"},400);
    const passwordHash = await makePasswordHash(password);
    return await db(env, async c => {
      await c.query("BEGIN");
      try {
       const id = crypto.randomUUID();
       await c.query('INSERT INTO "User" ("id","email","passwordHash","role","status","updatedAt") VALUES ($1,$2,$3,$4,$5,NOW())',[id,email,passwordHash,"CUSTOMER","ACTIVE"]);
       await c.query('INSERT INTO "Profile" ("id","userId","displayName","updatedAt") VALUES ($1,$2,$3,NOW())',[crypto.randomUUID(),id,displayName]);
       const session = await createUserSession(c,{id,email,role:"CUSTOMER",displayName});
       await c.query("COMMIT");
       return json({success:true,data:session},201);
      } catch(e) {
       await c.query("ROLLBACK");
       if ((e as {code?:string})?.code === "23505") return json({success:false,message:"Email sudah terdaftar"},409);
       throw e;
      }
    });
   } catch(e) { console.error("Registration failed",e); return json({success:false,message:"Pendaftaran gagal. Periksa data dan coba lagi."},400); }
  }
  if (path === "/api/v1/auth/user/login" && request.method === "POST") {
   try {
    const body = await readRequestBody(request);
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (!email || !password || password.length > 128) return json({success:false,message:"Email atau password tidak valid"},400);
    return await db(env, async c => {
      const result = await c.query('SELECT u."id",u."email",u."passwordHash",u."role",u."status",p."displayName" FROM "User" u LEFT JOIN "Profile" p ON p."userId"=u."id" WHERE u."email"=$1 LIMIT 1',[email]);
      const user = result.rows[0];
      if (!user || user.role === "ADMIN" || user.status !== "ACTIVE" || !(await checkPassword(password,user.passwordHash)))
        return json({success:false,message:"Email atau password tidak valid"},401);
      return json({success:true,data:await createUserSession(c,{id:user.id,email:user.email,role:user.role,displayName:user.displayName})});
    });
   } catch(e) { console.error("User login failed",e); return json({success:false,message:"Login gagal. Coba lagi."},400); }
  }

  if (path === "/api/v1/auth/logout" && request.method === "POST") {
   try {
    const header = request.headers.get("authorization") || "";
    const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
    if (/^[a-f0-9]{64}$/i.test(token)) {
      const tokenHash = await sha256(token);
      await db(env, c => c.query('DELETE FROM "UserSession" WHERE "tokenHash"=$1',[tokenHash]));
    }
    return json({success:true,message:"Sesi telah diakhiri"});
   } catch(e) { console.error("Logout failed",e); return json({success:false,message:"Tidak dapat mengakhiri sesi"},503); }
  }
  if (path === "/api/v1/auth/me" && request.method === "GET") {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      return user ? json({success:true,data:user}) : json({success:false,message:"Sesi tidak valid atau kedaluwarsa"},401);
    });
   } catch(e) { console.error("Session lookup failed",e); return json({success:false,message:"Tidak dapat memeriksa sesi"},503); }
  }

  if (path === "/api/v1/posts" && request.method === "POST") {
   try {
    const body = await readRequestBody(request);
    const content = typeof body.content === "string" ? body.content.trim() : "";
    const audience = typeof body.audience === "string" ? body.audience : "PUBLIC";
    if (!content || content.length > 2000) return json({success:false,message:"Isi postingan wajib diisi (maksimal 2.000 karakter)."},400);
    if (!["PUBLIC","FOLLOWERS","PRIVATE"].includes(audience)) return json({success:false,message:"Pilihan privasi tidak valid."},400);
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const id = crypto.randomUUID();
      const result = await c.query('INSERT INTO "Post" ("id","authorId","content","audience","createdAt","updatedAt") VALUES ($1,$2,$3,$4,NOW(),NOW()) RETURNING "id","authorId","content","audience","createdAt"',[id,user.id,content,audience]);
      return json({success:true,data:{...result.rows[0],authorName:user.displayName,authorAvatar:user.avatarUrl}},201);
    });
   } catch(e) { console.error("Create post failed",e); return json({success:false,message:"Postingan gagal disimpan. Coba lagi."},503); }
  }
  if (path === "/api/v1/posts" && request.method === "GET") {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const limit = Math.min(Math.max(Number(url.searchParams.get("limit")||30),1),50);
      const result = await c.query('SELECT p."id",p."authorId",p."content",p."audience",p."createdAt",pr."displayName" AS "authorName",pr."avatarUrl" AS "authorAvatar" FROM "Post" p JOIN "User" u ON u."id"=p."authorId" LEFT JOIN "Profile" pr ON pr."userId"=p."authorId" WHERE u."status"=\'ACTIVE\' AND (p."audience"=\'PUBLIC\' OR p."authorId"=$1 OR (p."audience"=\'FOLLOWERS\' AND EXISTS (SELECT 1 FROM "Follow" f WHERE f."followerId"=$1 AND f."followingId"=p."authorId"))) ORDER BY p."createdAt" DESC LIMIT $2',[user.id,limit]);
      return json({success:true,count:result.rowCount,data:result.rows});
    });
   } catch(e) { console.error("Load posts failed",e); return json({success:false,message:"Feed gagal dimuat."},503); }
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
