import { Client } from "pg";

interface Env {
  HYPERDRIVE: Hyperdrive;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method !== "GET") {
      return Response.json({ success: false, message: "Method not allowed" }, { status: 405 });
    }

    if (url.pathname === "/health") {
      return Response.json({ success: true, service: "yuku-api-worker", status: "ok" });
    }

    if (url.pathname === "/health/db") {
      const client = new Client({ connectionString: env.HYPERDRIVE.connectionString });
      try {
        await client.connect();
        const result = await client.query("SELECT current_database() AS database, NOW() AS server_time");
        return Response.json({
          success: true,
          service: "yuku-api-worker",
          database: "connected",
          databaseName: result.rows[0]?.database,
          checkedAt: result.rows[0]?.server_time,
        });
      } catch (error) {
        console.error("YUKU database health check failed", error);
        return Response.json({ success: false, database: "disconnected", message: "Database connection failed" }, { status: 503 });
      } finally {
        await client.end().catch(() => undefined);
      }
    }

    return Response.json({ success: false, message: "Not found" }, { status: 404 });
  },
} satisfies ExportedHandler<Env>;
