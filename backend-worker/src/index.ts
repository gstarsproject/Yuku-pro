import { Client } from "pg";
interface Env { HYPERDRIVE: Hyperdrive; AWS_ACCESS_KEY_ID: string; AWS_SECRET_ACCESS_KEY: string; AWS_ENDPOINT_URL_S3: string; AWS_REGION: string; }
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS", "Access-Control-Allow-Headers": "Content-Type, Authorization", "Content-Type": "application/json; charset=utf-8" };
const json = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: cors });
async function db<T>(env: Env, fn: (c: Client) => Promise<T>): Promise<T> {
  const c = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  try { await c.connect(); return await fn(c); } finally { await c.end().catch(() => undefined); }
}

const TOKEN_TTL_SECONDS = 28800;
const MAX_POST_CONTENT_LENGTH = 2000;
const encoder = new TextEncoder();
const toHex = (bytes: Uint8Array) => Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("");
async function sha256(value: string) {
  return toHex(new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(value))));
}

const awsEncode = (value: string) => encodeURIComponent(value).replace(/[!'()*]/g, c => "%" + c.charCodeAt(0).toString(16).toUpperCase());
const hexBytes = (value: ArrayBuffer) => toHex(new Uint8Array(value));
async function hmacBytes(key: ArrayBuffer | Uint8Array, value: string) {
  const imported = await crypto.subtle.importKey("raw", key instanceof Uint8Array ? key.slice().buffer as ArrayBuffer : key, {name:"HMAC",hash:"SHA-256"}, false, ["sign"]);
  return new Uint8Array(await crypto.subtle.sign("HMAC", imported, encoder.encode(value)));
}
async function presignMedia(env: Env, method: "GET"|"PUT", objectKey: string, expires = 900) {
  const now = new Date(), stamp = now.toISOString().replace(/[:-]|\.\d{3}/g,""), date = stamp.slice(0,8);
  const endpoint = new URL(env.AWS_ENDPOINT_URL_S3);
  const canonicalUri = "/" + ["mavo-media", ...objectKey.split("/")].map(awsEncode).join("/");
  const scope = date + "/" + env.AWS_REGION + "/s3/aws4_request";
  const params: [string,string][] = [
    ["X-Amz-Algorithm","AWS4-HMAC-SHA256"],
    ["X-Amz-Credential",env.AWS_ACCESS_KEY_ID + "/" + scope],
    ["X-Amz-Date",stamp],
    ["X-Amz-Expires",String(expires)],
    ["X-Amz-SignedHeaders","host"]
  ];
  const canonicalQuery = params.map(([k,v])=>[awsEncode(k),awsEncode(v)] as const).sort((a,b)=>a[0].localeCompare(b[0])).map(([k,v])=>k+"="+v).join("&");
  const canonicalRequest = method+"\n"+canonicalUri+"\n"+canonicalQuery+"\nhost:"+endpoint.host+"\n\nhost\nUNSIGNED-PAYLOAD";
  const stringToSign = "AWS4-HMAC-SHA256\n"+stamp+"\n"+scope+"\n"+await sha256(canonicalRequest);
  const kDate = await hmacBytes(encoder.encode("AWS4"+env.AWS_SECRET_ACCESS_KEY),date);
  const kRegion = await hmacBytes(kDate,env.AWS_REGION);
  const kService = await hmacBytes(kRegion,"s3");
  const kSigning = await hmacBytes(kService,"aws4_request");
  const signature = hexBytes(await crypto.subtle.sign("HMAC",await crypto.subtle.importKey("raw",kSigning,{name:"HMAC",hash:"SHA-256"},false,["sign"]),encoder.encode(stringToSign)));
  return endpoint.origin+canonicalUri+"?"+canonicalQuery+"&X-Amz-Signature="+signature;
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

  const profileMatch = path.match(/^\/api\/v1\/users\/([0-9a-f-]{36})\/profile$/i);
  if (profileMatch && request.method === "GET") {
   try {
    return await db(env, async c => {
      const viewer = await getSessionUser(c,request);
      if (!viewer) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const result = await c.query(`SELECT u."id",pr."displayName",pr."avatarUrl",pr."bio",(SELECT COUNT(*)::int FROM "Post" p WHERE p."authorId"=u."id") AS "postsCount",(SELECT COUNT(*)::int FROM "Follow" f WHERE f."followingId"=u."id") AS "followers",(SELECT COUNT(*)::int FROM "Follow" f WHERE f."followerId"=u."id") AS "followingCount",COALESCE(pp."verificationStatus"='VERIFIED',FALSE) AS "isVerified" FROM "User" u LEFT JOIN "Profile" pr ON pr."userId"=u."id" LEFT JOIN "ProviderProfile" pp ON pp."userId"=u."id" WHERE u."id"=$1 AND u."status"='ACTIVE' AND u."role"<>'ADMIN' LIMIT 1`,[profileMatch[1]]);
      if (!result.rows[0]) return json({success:false,message:"Profil tidak ditemukan."},404);
      return json({success:true,data:result.rows[0]});
    });
   } catch(e) { console.error("Profile lookup failed",e); return json({success:false,message:"Profil gagal dimuat."},503); }
  }
  if (path === "/api/v1/profile" && request.method === "PATCH") {
   try {
    const body = await readRequestBody(request);
    return await db(env, async c => {
      const viewer = await getSessionUser(c,request);
      if (!viewer) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const current = await c.query('SELECT "displayName","avatarUrl","bio" FROM "Profile" WHERE "userId"=$1 LIMIT 1',[viewer.id]);
      if (!current.rows[0]) return json({success:false,message:"Profil tidak ditemukan."},404);
      const displayName = typeof body.displayName === "string" ? body.displayName.trim() : current.rows[0].displayName;
      const bio = typeof body.bio === "string" ? body.bio.trim() : current.rows[0].bio;
      const avatarUrl = typeof body.avatarUrl === "string" ? body.avatarUrl.trim() : current.rows[0].avatarUrl;
      if (displayName.length < 2 || displayName.length > 40) return json({success:false,message:"Nama harus 2–40 karakter."},400);
      if (typeof bio === "string" && bio.length > 1000) return json({success:false,message:"Bio maksimal 1.000 karakter."},400);
      if (avatarUrl && (!/^https:\/\//i.test(avatarUrl) || avatarUrl.length > 2000)) return json({success:false,message:"URL foto harus menggunakan HTTPS."},400);
      const result = await c.query('UPDATE "Profile" SET "displayName"=$2,"bio"=$3,"avatarUrl"=$4,"updatedAt"=NOW() WHERE "userId"=$1 RETURNING "userId","displayName","avatarUrl","bio"',[viewer.id,displayName,bio || null,avatarUrl || null]);
      return json({success:true,data:result.rows[0]});
    });
   } catch(e) { console.error("Profile update failed",e); return json({success:false,message:"Profil gagal disimpan."},503); }
  }
  const followMatch = path.match(/^\/api\/v1\/users\/([0-9a-f-]{36})\/follow$/i);
  if (followMatch && ["GET","POST","DELETE"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const viewer = await getSessionUser(c,request);
      if (!viewer) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const targetId = followMatch[1];
      if (viewer.id === targetId) return json({success:false,message:"Kamu tidak bisa mengikuti akun sendiri."},400);
      const target = await c.query('SELECT "id" FROM "User" WHERE "id"=$1 AND "status"=\'ACTIVE\' AND "role"<>\'ADMIN\' LIMIT 1',[targetId]);
      if (!target.rows[0]) return json({success:false,message:"Akun tidak ditemukan."},404);
      if (request.method === "POST") {
        const created = await c.query('INSERT INTO "Follow" ("id","followerId","followingId","createdAt") VALUES ($1,$2,$3,NOW()) ON CONFLICT ("followerId","followingId") DO NOTHING RETURNING "id"',[crypto.randomUUID(),viewer.id,targetId]);
        if (created.rows[0]) await c.query('INSERT INTO "Notification" ("id","recipientId","actorId","type","entityId","message","createdAt") VALUES ($1,$2,$3,\'FOLLOW\',$4,$5,NOW())',[crypto.randomUUID(),targetId,viewer.id,targetId,(viewer.displayName || "Seseorang") + " mulai mengikuti kamu."]);
      } else if (request.method === "DELETE") {
        await c.query('DELETE FROM "Follow" WHERE "followerId"=$1 AND "followingId"=$2',[viewer.id,targetId]);
      }
      const result = await c.query('SELECT EXISTS(SELECT 1 FROM "Follow" WHERE "followerId"=$1 AND "followingId"=$2) AS following, (SELECT COUNT(*)::int FROM "Follow" WHERE "followingId"=$2) AS followers, (SELECT COUNT(*)::int FROM "Follow" WHERE "followerId"=$2) AS followingCount',[viewer.id,targetId]);
      return json({success:true,data:result.rows[0]});
    });
   } catch(e) { console.error("Follow operation failed",e); return json({success:false,message:"Tidak dapat memperbarui pengikut."},503); }
  }
  const relationMatch = path.match(/^\/api\/v1\/users\/([0-9a-f-]{36})\/relations$/i);
  if (relationMatch && request.method === "GET") {
   try {
    return await db(env, async c => {
      const viewer = await getSessionUser(c,request);
      if (!viewer) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const targetId = relationMatch[1];
      const type = url.searchParams.get("type") === "following" ? "following" : "followers";
      const result = type === "followers"
        ? await c.query('SELECT u."id",p."displayName",p."avatarUrl",EXISTS(SELECT 1 FROM "Follow" mine WHERE mine."followerId"=$1 AND mine."followingId"=u."id") AS "following" FROM "Follow" f JOIN "User" u ON u."id"=f."followerId" JOIN "Profile" p ON p."userId"=u."id" WHERE f."followingId"=$2 AND u."status"=\'ACTIVE\' ORDER BY f."createdAt" DESC LIMIT 200',[viewer.id,targetId])
        : await c.query('SELECT u."id",p."displayName",p."avatarUrl",EXISTS(SELECT 1 FROM "Follow" mine WHERE mine."followerId"=$1 AND mine."followingId"=u."id") AS "following" FROM "Follow" f JOIN "User" u ON u."id"=f."followingId" JOIN "Profile" p ON p."userId"=u."id" WHERE f."followerId"=$2 AND u."status"=\'ACTIVE\' ORDER BY f."createdAt" DESC LIMIT 200',[viewer.id,targetId]);
      return json({success:true,count:result.rowCount,data:result.rows});
    });
   } catch(e) { console.error("User relations request failed",e); return json({success:false,message:"Daftar pengikut gagal dimuat."},503); }
  }

  if (path === "/api/v1/media/upload-url" && request.method === "POST") {
   try {
    const body = await readRequestBody(request);
    const contentType = typeof body.contentType === "string" ? body.contentType.toLowerCase() : "";
    const mediaType = typeof body.mediaType === "string" ? body.mediaType.toUpperCase() : "";
    const byteSize = Number(body.byteSize || 0);
    const allowed = mediaType === "IMAGE" ? ["image/jpeg","image/png","image/webp","image/gif"] : mediaType === "VIDEO" ? ["video/mp4","video/quicktime"] : [];
    const maxBytes = mediaType === "VIDEO" ? 100*1024*1024 : 20*1024*1024;
    if (!allowed.includes(contentType) || !Number.isSafeInteger(byteSize) || byteSize < 1 || byteSize > maxBytes)
      return json({success:false,message:"Format atau ukuran file tidak didukung (foto maks. 20 MB, video maks. 100 MB)."},400);
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const extension = contentType.split("/")[1].replace("jpeg","jpg").replace("quicktime","mov");
      const objectKey = "users/"+user.id+"/"+crypto.randomUUID()+"."+extension;
      const uploadUrl = await presignMedia(env,"PUT",objectKey,900);
      return json({success:true,data:{objectKey,uploadUrl,method:"PUT",headers:{"Content-Type":contentType},expiresIn:900}});
    });
   } catch(e) { console.error("Media upload URL failed",e); return json({success:false,message:"Tidak dapat menyiapkan upload media."},503); }
  }
  const mediaUrlMatch = path.match(/^\/api\/v1\/media\/([0-9a-f-]{36})\/url$/i);
  if (mediaUrlMatch && request.method === "GET") {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const result = await c.query(`SELECT m."objectKey",m."contentType",m."mediaType",m."ownerId",p."audience" AS "postAudience",p."authorId" AS "postAuthor",s."audience" AS "storyAudience",s."userId" AS "storyAuthor",s."expiresAt" AS "storyExpires" FROM "MediaAsset" m LEFT JOIN "Post" p ON p."id"=m."postId" LEFT JOIN "Story" s ON s."id"=m."storyId" WHERE m."id"=$1 LIMIT 1`,[mediaUrlMatch[1]]);
      const media = result.rows[0];
      if (!media) return json({success:false,message:"Media tidak ditemukan."},404);
      let visible = media.ownerId === user.id;
      if (media.postAuthor) visible = visible || media.postAudience === "PUBLIC" || (media.postAudience === "FOLLOWERS" && !!(await c.query('SELECT 1 FROM "Follow" WHERE "followerId"=$1 AND "followingId"=$2',[user.id,media.postAuthor])).rows[0]);
      if (media.storyAuthor && new Date(media.storyExpires).getTime() > Date.now()) visible = visible || media.storyAudience === "PUBLIC" || (media.storyAudience === "FOLLOWERS" && !!(await c.query('SELECT 1 FROM "Follow" WHERE "followerId"=$1 AND "followingId"=$2',[user.id,media.storyAuthor])).rows[0]);
      if (!visible) return json({success:false,message:"Kamu tidak memiliki akses ke media ini."},403);
      const downloadUrl = await presignMedia(env,"GET",media.objectKey,900);
      return json({success:true,data:{downloadUrl,contentType:media.contentType,mediaType:media.mediaType,expiresIn:900}});
    });
   } catch(e) { console.error("Media download URL failed",e); return json({success:false,message:"Media gagal dimuat."},503); }
  }

  if (path === "/api/v1/posts" && request.method === "POST") {
   try {
    const body = await readRequestBody(request);
    const content = typeof body.content === "string" ? body.content.trim() : "";
    const audience = typeof body.audience === "string" ? body.audience : "PUBLIC";
    const media = Array.isArray(body.media) ? body.media : [];
    const locationName = typeof body.locationName === "string" ? body.locationName.trim().slice(0,200) : null;
    const latitude = typeof body.latitude === "number" ? body.latitude : null;
    const longitude = typeof body.longitude === "number" ? body.longitude : null;
    if ((!content && media.length === 0) || content.length > MAX_POST_CONTENT_LENGTH || media.length > 10) return json({success:false,message:"Isi postingan atau media wajib diisi (maksimal 10 file)."},400);
    if (!["PUBLIC","FOLLOWERS","PRIVATE"].includes(audience)) return json({success:false,message:"Pilihan privasi tidak valid."},400);
    if ((latitude === null) !== (longitude === null) || (latitude !== null && (Math.abs(latitude)>90 || Math.abs(longitude!)>180))) return json({success:false,message:"Koordinat lokasi tidak valid."},400);
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      for (const item of media) {
        if (!item || typeof item.objectKey !== "string" || !item.objectKey.startsWith("users/"+user.id+"/") ||
            !["IMAGE","VIDEO"].includes(item.mediaType) || typeof item.contentType !== "string" ||
            !Number.isSafeInteger(Number(item.byteSize)) || Number(item.byteSize)<1) return json({success:false,message:"Data media tidak valid."},400);
      }
      const id = crypto.randomUUID();
      await c.query("BEGIN");
      try {
        const result = await c.query('INSERT INTO "Post" ("id","authorId","content","audience","locationName","latitude","longitude","createdAt","updatedAt") VALUES ($1,$2,$3,$4,$5,$6,$7,NOW(),NOW()) RETURNING "id","authorId","content","audience","locationName","latitude","longitude","createdAt"',[id,user.id,content,audience,locationName,latitude,longitude]);
        for (let i=0;i<media.length;i++) {
          const item=media[i];
          await c.query('INSERT INTO "MediaAsset" ("id","ownerId","postId","mediaType","objectKey","contentType","byteSize","sortOrder","createdAt") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())',[crypto.randomUUID(),user.id,id,item.mediaType,item.objectKey,item.contentType,Number(item.byteSize),i]);
        }
        await c.query("COMMIT");
        return json({success:true,data:{...result.rows[0],authorName:user.displayName,authorAvatar:user.avatarUrl}},201);
      } catch(e) { await c.query("ROLLBACK"); throw e; }
    });
   } catch(e) { console.error("Create post failed",e); return json({success:false,message:"Postingan gagal disimpan. Coba lagi."},503); }
  }
  if (path === "/api/v1/users/search" && request.method === "GET") {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const query = (url.searchParams.get("q") || "").trim();
      if (query.length < 2 || query.length > 60) return json({success:true,count:0,data:[]});
      const result = await c.query('SELECT u."id",p."displayName",p."avatarUrl" FROM "User" u JOIN "Profile" p ON p."userId"=u."id" WHERE u."status"=\'ACTIVE\' AND u."role"<>\'ADMIN\' AND u."id"<>$1 AND p."displayName" ILIKE $2 ORDER BY p."displayName" ASC LIMIT 20',[user.id,'%' + query + '%']);
      return json({success:true,count:result.rowCount,data:result.rows});
    });
   } catch(e) { console.error("User search failed",e); return json({success:false,message:"Pencarian pengguna gagal."},503); }
  }
  // Direct chat endpoints are participant-scoped; keep this check before message access.
  if (path === "/api/v1/conversations" && ["GET","POST"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      if (request.method === "POST") {
        const body = await readRequestBody(request);
        const recipientId = typeof body.recipientId === "string" ? body.recipientId : "";
        if (!/^[0-9a-f-]{36}$/i.test(recipientId) || recipientId === user.id) return json({success:false,message:"Pengguna tujuan tidak valid."},400);
        const target = await c.query('SELECT "id" FROM "User" WHERE "id"=$1 AND "status"=\'ACTIVE\' AND "role"<>\'ADMIN\' LIMIT 1',[recipientId]);
        if (!target.rows[0]) return json({success:false,message:"Pengguna tidak ditemukan."},404);
        const directKey = [user.id,recipientId].sort().join(":");
        const inserted = await c.query('INSERT INTO "Conversation" ("id","directKey","createdAt") VALUES ($1,$2,NOW()) ON CONFLICT ("directKey") DO NOTHING RETURNING "id"',[crypto.randomUUID(),directKey]);
        let conversationId = inserted.rows[0]?.id;
        if (!conversationId) {
          const existing = await c.query('SELECT "id" FROM "Conversation" WHERE "directKey"=$1 LIMIT 1',[directKey]);
          conversationId = existing.rows[0]?.id;
        }
        if (!conversationId) throw new Error("Conversation could not be created");
        await c.query('INSERT INTO "ConversationParticipant" ("id","conversationId","userId") VALUES ($1,$2,$3),($4,$2,$5) ON CONFLICT ("conversationId","userId") DO NOTHING',[crypto.randomUUID(),conversationId,user.id,crypto.randomUUID(),recipientId]);
        return json({success:true,data:{id:conversationId,recipientId}},201);
      }
      const result = await c.query('SELECT cv."id",peer."id" AS "userId",pr."displayName",pr."avatarUrl",lm."body" AS "lastMessage",lm."createdAt" AS "lastMessageAt",(SELECT COUNT(*)::int FROM "Message" um WHERE um."conversationId"=cv."id" AND um."senderId"<>$1 AND um."readAt" IS NULL) AS "unreadCount" FROM "ConversationParticipant" mine JOIN "Conversation" cv ON cv."id"=mine."conversationId" JOIN "ConversationParticipant" other ON other."conversationId"=cv."id" AND other."userId"<>$1 JOIN "User" peer ON peer."id"=other."userId" AND peer."status"=\'ACTIVE\' LEFT JOIN "Profile" pr ON pr."userId"=peer."id" LEFT JOIN LATERAL (SELECT m."body",m."createdAt" FROM "Message" m WHERE m."conversationId"=cv."id" ORDER BY m."createdAt" DESC LIMIT 1) lm ON TRUE WHERE mine."userId"=$1 ORDER BY COALESCE(lm."createdAt",cv."createdAt") DESC LIMIT 100',[user.id]);
      return json({success:true,count:result.rowCount,data:result.rows});
    });
   } catch(e) { console.error("Conversations request failed",e); return json({success:false,message:"Percakapan gagal dimuat."},503); }
  }
  const messageMatch = path.match(/^\/api\/v1\/conversations\/([0-9a-f-]{36})\/(messages|read)$/i);
  if (messageMatch && ["GET","POST"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const conversationId = messageMatch[1], action = messageMatch[2].toLowerCase();
      const membership = await c.query('SELECT 1 FROM "ConversationParticipant" WHERE "conversationId"=$1 AND "userId"=$2 LIMIT 1',[conversationId,user.id]);
      if (!membership.rows[0]) return json({success:false,message:"Percakapan tidak ditemukan."},404);
      if (action === "read") {
        if (request.method !== "POST") return json({success:false,message:"Method not allowed"},405);
        await c.query('UPDATE "Message" SET "readAt"=NOW() WHERE "conversationId"=$1 AND "senderId"<>$2 AND "readAt" IS NULL',[conversationId,user.id]);
        await c.query('UPDATE "Notification" SET "readAt"=NOW() WHERE "recipientId"=$1 AND "type"=\'MESSAGE\' AND "entityId"=$2 AND "readAt" IS NULL',[user.id,conversationId]);
        return json({success:true,data:{conversationId,read:true}});
      }
      if (request.method === "GET") {
        const result = await c.query('SELECT m."id",m."senderId",m."body",m."createdAt",m."readAt",p."displayName" AS "senderName",p."avatarUrl" AS "senderAvatar" FROM "Message" m LEFT JOIN "Profile" p ON p."userId"=m."senderId" WHERE m."conversationId"=$1 ORDER BY m."createdAt" ASC LIMIT 200',[conversationId]);
        return json({success:true,count:result.rowCount,data:result.rows});
      }
      const body = await readRequestBody(request), content = typeof body.content === "string" ? body.content.trim() : "";
      if (!content || content.length > 5000) return json({success:false,message:"Pesan wajib diisi (maksimal 5.000 karakter)."},400);
      const inserted = await c.query('INSERT INTO "Message" ("id","conversationId","senderId","body","createdAt") VALUES ($1,$2,$3,$4,NOW()) RETURNING "id","conversationId","senderId","body","createdAt","readAt"',[crypto.randomUUID(),conversationId,user.id,content]);
      const peers = await c.query('SELECT "userId" FROM "ConversationParticipant" WHERE "conversationId"=$1 AND "userId"<>$2',[conversationId,user.id]);
      for (const peer of peers.rows) {
        await c.query('INSERT INTO "Notification" ("id","recipientId","actorId","type","entityId","message","createdAt") VALUES ($1,$2,$3,\'MESSAGE\',$4,$5,NOW())',[crypto.randomUUID(),peer.userId,user.id,conversationId,(user.displayName || "Pengguna") + ": " + content.slice(0,400)]);
      }
      return json({success:true,data:{...inserted.rows[0],senderName:user.displayName,senderAvatar:user.avatarUrl}},201);
    });
   } catch(e) { console.error("Messages request failed",e); return json({success:false,message:"Pesan gagal diproses."},503); }
  }
  if (path === "/api/v1/notifications" && ["GET","POST"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      if (request.method === "POST") {
        await c.query('UPDATE "Notification" SET "readAt"=NOW() WHERE "recipientId"=$1 AND "readAt" IS NULL',[user.id]);
        return json({success:true,data:{markedRead:true}});
      }
      const result = await c.query('SELECT n."id",n."type",n."entityId",n."message",n."createdAt",n."readAt",p."displayName" AS "actorName",p."avatarUrl" AS "actorAvatar" FROM "Notification" n LEFT JOIN "Profile" p ON p."userId"=n."actorId" WHERE n."recipientId"=$1 ORDER BY n."createdAt" DESC LIMIT 100',[user.id]);
      const unread = await c.query('SELECT COUNT(*)::int AS count FROM "Notification" WHERE "recipientId"=$1 AND "readAt" IS NULL',[user.id]);
      return json({success:true,count:result.rowCount,unreadCount:unread.rows[0]?.count || 0,data:result.rows});
    });
   } catch(e) { console.error("Notifications request failed",e); return json({success:false,message:"Notifikasi gagal dimuat."},503); }
  }
  if (path === "/api/v1/stories" && ["GET","POST"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      if (request.method === "POST") {
        const body = await readRequestBody(request);
        const content = typeof body.content === "string" ? body.content.trim() : "";
        const audience = typeof body.audience === "string" ? body.audience.toUpperCase() : "PUBLIC";
        const media = Array.isArray(body.media) ? body.media : [];
        const locationName = typeof body.locationName === "string" ? body.locationName.trim().slice(0,200) : null;
        const latitude = typeof body.latitude === "number" ? body.latitude : null;
        const longitude = typeof body.longitude === "number" ? body.longitude : null;
        if ((!content && media.length === 0) || content.length > 500 || media.length > 10) return json({success:false,message:"Story harus berisi teks atau media (maksimal 10 file)."},400);
        if (!["PUBLIC","FOLLOWERS"].includes(audience)) return json({success:false,message:"Pilihan privasi story tidak valid."},400);
        if ((latitude === null) !== (longitude === null) || (latitude !== null && (Math.abs(latitude)>90 || Math.abs(longitude!)>180))) return json({success:false,message:"Koordinat lokasi tidak valid."},400);
        for (const item of media) {
          if (!item || typeof item.objectKey !== "string" || !item.objectKey.startsWith("users/"+user.id+"/") || !["IMAGE","VIDEO"].includes(item.mediaType) || typeof item.contentType !== "string" || !Number.isSafeInteger(Number(item.byteSize)) || Number(item.byteSize)<1) return json({success:false,message:"Data media tidak valid."},400);
        }
        const id = crypto.randomUUID();
        await c.query("BEGIN");
        try {
          const result = await c.query('INSERT INTO "Story" ("id","userId","content","audience","locationName","latitude","longitude","createdAt","expiresAt") VALUES ($1,$2,$3,$4,$5,$6,$7,NOW(),NOW()+INTERVAL \'24 hours\') RETURNING "id","userId","content","audience","locationName","latitude","longitude","createdAt","expiresAt"',[id,user.id,content,audience,locationName,latitude,longitude]);
          for (let i=0;i<media.length;i++) {
            const item=media[i];
            await c.query('INSERT INTO "MediaAsset" ("id","ownerId","storyId","mediaType","objectKey","contentType","byteSize","sortOrder","createdAt") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())',[crypto.randomUUID(),user.id,id,item.mediaType,item.objectKey,item.contentType,Number(item.byteSize),i]);
          }
          await c.query("COMMIT");
          return json({success:true,data:{...result.rows[0],authorName:user.displayName,authorAvatar:user.avatarUrl}},201);
        } catch(e) { await c.query("ROLLBACK"); throw e; }
      }
      const result = await c.query('SELECT s."id",s."userId",s."content",s."audience",s."createdAt",s."expiresAt",s."locationName",(SELECT COALESCE(json_agg(json_build_object(\'id\',ma."id",\'mediaType\',ma."mediaType",\'contentType\',ma."contentType\') ORDER BY ma."sortOrder"),'[]'::json) FROM "MediaAsset" ma WHERE ma."storyId"=s."id") AS "media",p."displayName" AS "authorName",p."avatarUrl" AS "authorAvatar" FROM "Story" s JOIN "User" u ON u."id"=s."userId" LEFT JOIN "Profile" p ON p."userId"=s."userId" WHERE s."expiresAt">NOW() AND u."status"=\'ACTIVE\' AND (s."audience"=\'PUBLIC\' OR s."userId"=$1 OR (s."audience"=\'FOLLOWERS\' AND EXISTS (SELECT 1 FROM "Follow" f WHERE f."followerId"=$1 AND f."followingId"=s."userId"))) ORDER BY s."createdAt" DESC LIMIT 100',[user.id]);
      return json({success:true,count:result.rowCount,data:result.rows});
    });
   } catch(e) { console.error("Stories request failed",e); return json({success:false,message:"Story gagal diproses."},503); }
  }
  const postInteractionMatch = path.match(/^\/api\/v1\/posts\/([0-9a-f-]{36})\/(like|comments)$/i);
  if (postInteractionMatch && ["GET","POST","DELETE"].includes(request.method)) {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const postId = postInteractionMatch[1], action = postInteractionMatch[2].toLowerCase();
      const visible = await c.query('SELECT p."id",p."authorId" FROM "Post" p JOIN "User" u ON u."id"=p."authorId" WHERE p."id"=$1 AND u."status"=\'ACTIVE\' AND (p."audience"=\'PUBLIC\' OR p."authorId"=$2 OR (p."audience"=\'FOLLOWERS\' AND EXISTS (SELECT 1 FROM "Follow" f WHERE f."followerId"=$2 AND f."followingId"=p."authorId"))) LIMIT 1',[postId,user.id]);
      if (!visible.rows[0]) return json({success:false,message:"Postingan tidak ditemukan atau tidak dapat diakses."},404);
      if (action === "like") {
        if (request.method === "GET") {
          const state = await c.query('SELECT EXISTS(SELECT 1 FROM "PostLike" WHERE "postId"=$1 AND "userId"=$2) AS "likedByMe",(SELECT COUNT(*)::int FROM "PostLike" WHERE "postId"=$1) AS "likesCount"',[postId,user.id]);
          return json({success:true,data:state.rows[0]});
        }
        if (request.method === "POST") {
          const liked = await c.query('INSERT INTO "PostLike" ("id","postId","userId","createdAt") VALUES ($1,$2,$3,NOW()) ON CONFLICT ("postId","userId") DO NOTHING RETURNING "id"',[crypto.randomUUID(),postId,user.id]);
          if (liked.rows[0] && visible.rows[0].authorId !== user.id) await c.query('INSERT INTO "Notification" ("id","recipientId","actorId","type","entityId","message","createdAt") VALUES ($1,$2,$3,\'LIKE\',$4,$5,NOW())',[crypto.randomUUID(),visible.rows[0].authorId,user.id,postId,(user.displayName || "Seseorang") + " menyukai postinganmu."]);
        }
        else await c.query('DELETE FROM "PostLike" WHERE "postId"=$1 AND "userId"=$2',[postId,user.id]);
        const state = await c.query('SELECT EXISTS(SELECT 1 FROM "PostLike" WHERE "postId"=$1 AND "userId"=$2) AS "likedByMe",(SELECT COUNT(*)::int FROM "PostLike" WHERE "postId"=$1) AS "likesCount"',[postId,user.id]);
        return json({success:true,data:state.rows[0]});
      }
      if (request.method === "GET") {
        const comments = await c.query('SELECT cm."id",cm."content",cm."createdAt",cm."userId",pr."displayName" AS "authorName",pr."avatarUrl" AS "authorAvatar" FROM "PostComment" cm LEFT JOIN "Profile" pr ON pr."userId"=cm."userId" WHERE cm."postId"=$1 ORDER BY cm."createdAt" ASC LIMIT 100',[postId]);
        return json({success:true,count:comments.rowCount,data:comments.rows});
      }
      if (request.method !== "POST") return json({success:false,message:"Method not allowed"},405);
      const body = await readRequestBody(request), content = typeof body.content === "string" ? body.content.trim() : "";
      if (!content || content.length > 1000) return json({success:false,message:"Komentar wajib diisi (maksimal 1.000 karakter)."},400);
      const inserted = await c.query('INSERT INTO "PostComment" ("id","postId","userId","content","createdAt") VALUES ($1,$2,$3,$4,NOW()) RETURNING "id","postId","userId","content","createdAt"',[crypto.randomUUID(),postId,user.id,content]);
      if (visible.rows[0].authorId !== user.id) await c.query('INSERT INTO "Notification" ("id","recipientId","actorId","type","entityId","message","createdAt") VALUES ($1,$2,$3,\'COMMENT\',$4,$5,NOW())',[crypto.randomUUID(),visible.rows[0].authorId,user.id,postId,(user.displayName || "Seseorang") + " mengomentari postinganmu."]);
      return json({success:true,data:{...inserted.rows[0],authorName:user.displayName,authorAvatar:user.avatarUrl}},201);
    });
   } catch(e) { console.error("Post interaction failed",e); return json({success:false,message:"Interaksi postingan gagal diproses."},503); }
  }

  if (path === "/api/v1/posts" && request.method === "GET") {
   try {
    return await db(env, async c => {
      const user = await getSessionUser(c,request);
      if (!user) return json({success:false,message:"Sesi tidak valid. Silakan login kembali."},401);
      const limit = Math.min(Math.max(Number(url.searchParams.get("limit")||30),1),50);
      const result = await c.query('SELECT p."id",p."authorId",p."content",p."audience",p."createdAt",pr."displayName" AS "authorName",pr."avatarUrl" AS "authorAvatar",(SELECT COUNT(*)::int FROM "PostLike" l WHERE l."postId"=p."id") AS "likesCount",(SELECT COUNT(*)::int FROM "PostComment" cm WHERE cm."postId"=p."id") AS "commentsCount",EXISTS(SELECT 1 FROM "PostLike" ml WHERE ml."postId"=p."id" AND ml."userId"=$1) AS "likedByMe",p."locationName",(SELECT COALESCE(json_agg(json_build_object(\'id\',ma."id",\'mediaType\',ma."mediaType",\'contentType\',ma."contentType\') ORDER BY ma."sortOrder"),'[]'::json) FROM "MediaAsset" ma WHERE ma."postId"=p."id") AS "media" FROM "Post" p JOIN "User" u ON u."id"=p."authorId" LEFT JOIN "Profile" pr ON pr."userId"=p."authorId" WHERE u."status"=\'ACTIVE\' AND (p."audience"=\'PUBLIC\' OR p."authorId"=$1 OR (p."audience"=\'FOLLOWERS\' AND EXISTS (SELECT 1 FROM "Follow" f WHERE f."followerId"=$1 AND f."followingId"=p."authorId"))) ORDER BY p."createdAt" DESC LIMIT $2',[user.id,limit]);
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
