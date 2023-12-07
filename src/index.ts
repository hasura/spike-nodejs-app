import Fastify from 'fastify';

export const LOG_LEVEL = process.env["LOG_LEVEL"] ?? "info";
export const PRETTY_PRINT_LOGS = process.env["PRETTY_PRINT_LOGS"] === "1" || process.env["PRETTY_PRINT_LOGS"] === "true";

const port = Number(process.env.PORT) || 8100;

const server = Fastify({
  logger:
    {
      level: LOG_LEVEL,
      ...(
        PRETTY_PRINT_LOGS
          ? { transport: { target: 'pino-pretty' } }
          : {}
      )
    }
})

server.get("/health", async (request, response) => {
  response.statusCode = 204;
});

process.on('SIGINT', () => {
  server.log.info("interrupted");
  process.exit(0);
});

const start = async () => {
  try {
    await server.listen({port: port, host: "0.0.0.0"});
  }
  catch (err) {
    server.log.fatal(err);
    process.exit(1);
  }
};
start();
