export const neonInfrastructure = Object.freeze({
  schema: "file-tunnel.neon-infra/v1",
  terraformModule: "./terraform",
  environmentsRoot: "../../environments",
  credentials: Object.freeze({ apiKeyEnv: "NEON_API_KEY" }),
  applyPolicy: "operator-reviewed-only",
});

export default neonInfrastructure;
