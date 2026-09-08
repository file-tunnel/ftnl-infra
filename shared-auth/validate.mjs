import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const t = JSON.parse(fs.readFileSync(path.join(here, "topology.json"), "utf8"));
const directPin = "511abec23ce83344abdc2686e313cc1dfc8de3e3";
const middlewarePin = "d02f97b92857bc8d23d53438913e169d7f04a974";
const contractPin = "efdae470aa45fd52a59ce99da5068c3b637f37cd";
const bindings = {
  "web-server": ["customer-auth", "SUPABASE_AUTH_DATABASE_URL", "NEON_AUTH_DATABASE_URL"],
  "api-server": ["customer-auth", "SUPABASE_AUTH_DATABASE_URL", "NEON_AUTH_DATABASE_URL"],
  "admin-web-server": ["admin-auth", "SUPABASE_ADMIN_DATABASE_URL", "NEON_ADMIN_DATABASE_URL"],
  "admin-api-server": ["admin-auth", "SUPABASE_ADMIN_DATABASE_URL", "NEON_ADMIN_DATABASE_URL"],
};
const ok = (value, message) => { if (!value) throw new Error(message); };
const noSecrets = (value, label) => {
  const text = typeof value === "string" ? value : JSON.stringify(value);
  ok(!/postgres(?:ql)?:\/\//i.test(text), `${label}: database URL committed`);
  ok(!/BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY/i.test(text), `${label}: private key committed`);
  ok(!/eyJ[\w-]{10,}\.[\w-]{10,}\./.test(text), `${label}: bearer/JWT material committed`);
};

ok(t.contract === "SharedAuthTopology" && t.version === 2, "wrong topology contract");
ok(t.linearIssue === "DEN-2843" && t.runtimeState === "source-only", "wrong rollout state");
ok(t.contractSource?.repository === "shared-auth/shared-auth-infra", "wrong contract repository");
ok(t.contractSource?.commit === contractPin, "contract source is not immutably pinned");
ok(t.contractSource?.path === "scripts/validate-shared-auth-runtime-contract.mjs", "wrong contract path");
ok(/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(t.githubOrg), "invalid GitHub organization");

for (const [provider, customerKey, adminKey] of [
  [t.supabase, "SUPABASE_AUTH_DATABASE_URL", "SUPABASE_ADMIN_DATABASE_URL"],
  [t.neon, "NEON_AUTH_DATABASE_URL", "NEON_ADMIN_DATABASE_URL"],
]) {
  ok(provider?.targetOrg === t.githubOrg, "provider target does not match GitHub org");
  ok(provider?.authDatabaseUrlEnv === customerKey, `wrong customer key: ${customerKey}`);
  ok(provider?.adminDatabaseUrlEnv === adminKey, `wrong admin key: ${adminKey}`);
}
if (t.supabase.placement === "shared-org-schema") {
  ok(t.supabase.runtimeOrg === "oresoftware", "temporary Supabase runtime must be oresoftware");
  ok(/^[a-z_][a-z0-9_]*$/.test(t.supabase.schema), "Supabase schema isolation missing");
  ok(t.supabase.transition?.kind === "explicit-waiver", "Supabase waiver missing");
  ok(t.supabase.transition?.issue === "DEN-2843", "Supabase waiver has wrong issue");
  ok(t.supabase.transition?.targetPlacement === "dedicated-org", "Supabase waiver has wrong target");
  ok(t.supabase.transition?.expiresOn >= "2026-09-07", "Supabase waiver expired");
} else {
  ok(t.supabase.placement === "dedicated-org", "invalid Supabase placement");
  ok(t.supabase.runtimeOrg === t.githubOrg && t.supabase.transition === null, "dedicated Supabase mapping invalid");
}
ok(t.neon.placement === "dedicated-org", "Neon must be dedicated");
ok(t.neon.runtimeOrg === t.githubOrg && t.neon.transition === null, "Neon mapping invalid");

const p = t.requestPolicy;
ok(p.requireBothProvidersConfigured === true && p.startupMode === "strict-paired-config", "startup must require both providers");
ok(["availability-first", "strict-paired"].includes(p.customerMode), "invalid customer mode");
ok(p.adminMode === "strict-paired" && p.sensitiveMode === "strict-paired", "admin/sensitive proof must be strict-paired");
ok(p.providerDisagreement === "deny", "provider disagreement must deny");
ok(p.missingProof === "deny-unless-explicit-customer-degraded-mode", "missing proof policy invalid");
ok(p.canonicalSubjectBinding === "shared-auth-user-id", "wrong canonical subject");

ok(Object.keys(t.roleBindings ?? {}).sort().join() === Object.keys(bindings).sort().join(), "four role bindings required");
ok(Object.keys(t.roleIntegrations ?? {}).sort().join() === Object.keys(bindings).sort().join(), "four role integrations required");
for (const [role, [realm, supabaseKey, neonKey]] of Object.entries(bindings)) {
  const b = t.roleBindings[role];
  ok(b.realm === realm && b.supabaseDatabaseUrlEnv === supabaseKey && b.neonDatabaseUrlEnv === neonKey, `${role}: wrong realm/database keys`);
  const i = t.roleIntegrations[role];
  ok(i.repository.startsWith(`${t.githubOrg}/`), `${role}: cross-org repository`);
  ok(["direct", "ores-middleware"].includes(i.target), `${role}: invalid integration`);
  ok(["blocked", "piloting"].includes(i.status), `${role}: unproven enabled claim`);
  ok(i.authority === "github.com/shared-auth" && i.singleDecisionPath === true, `${role}: identity authority split`);
  ok(i.allowProviderTokensAtApplicationBoundary === false, `${role}: raw provider tokens allowed`);
  ok(i.allowProductLocalHumanVerifier === false, `${role}: local human verifier allowed`);
  ok(Object.values(i.evidence ?? {}).every((value) => value === null || value === false), `${role}: source-only evidence overclaimed`);
  if (i.target === "direct") {
    ok(i.clientPackage === "shared-auth-service-client" && i.immutableClientPin === directPin, `${role}: direct client pin invalid`);
    ok(i.middlewareAuthVerifier === null && i.immutableAdapterPin === null, `${role}: duplicate middleware path`);
  } else {
    ok(i.clientPackage === null && i.immutableClientPin === null, `${role}: duplicate direct path`);
    ok(i.middlewareAuthVerifier === "shared-auth" && i.rejectAnonymousDefault === true, `${role}: AnonymousAuth not rejected`);
    ok(i.immutableAdapterPin === middlewarePin, `${role}: middleware pin invalid`);
  }
}
ok(Array.isArray(t.auditRepositories) && t.auditRepositories.length === 5, "exactly five audited repos required");
ok(new Set(t.auditRepositories).size === 5, "duplicate audited repo");
ok(t.auditRepositories.every((repo) => repo.startsWith(`${t.githubOrg}/`)), "cross-org audit entry");
const audited = new Set(t.auditRepositories);
for (const finding of t.findings ?? []) {
  ok(["high", "critical"].includes(finding.severity) && finding.status === "open", `invalid finding: ${finding.code}`);
  ok(audited.has(finding.repository) && finding.detail?.length >= 40, `unactionable finding: ${finding.code}`);
}
for (const i of Object.values(t.roleIntegrations)) {
  if (i.status === "blocked") ok((t.findings ?? []).some((f) => f.repository === i.repository), `blocked repo lacks finding: ${i.repository}`);
}

for (const [provider, realm, key, file] of [
  ["supabase", "customer-auth", "SUPABASE_AUTH_DATABASE_URL", "supabase/auth/migrations/202609080001_shared_auth_runtime_policy.sql"],
  ["supabase", "admin-auth", "SUPABASE_ADMIN_DATABASE_URL", "supabase/admin/migrations/202609080001_shared_auth_runtime_policy.sql"],
  ["neon", "customer-auth", "NEON_AUTH_DATABASE_URL", "neon/auth/migrations/202609080001_shared_auth_runtime_policy.sql"],
  ["neon", "admin-auth", "NEON_ADMIN_DATABASE_URL", "neon/admin/migrations/202609080001_shared_auth_runtime_policy.sql"],
]) {
  const sql = fs.readFileSync(path.join(root, file), "utf8");
  for (const literal of [t.githubOrg, provider, realm, key]) ok(sql.includes(`'${literal}'`), `${file}: missing ${literal}`);
  ok(/enable row level security/i.test(sql) && /revoke all/i.test(sql), `${file}: access hardening missing`);
  ok(/on conflict \(singleton\)/i.test(sql), `${file}: bounded reconciliation missing`);
  noSecrets(sql, file);
}
noSecrets(t, "topology");
console.log(`validated fail-closed Shared Auth topology for ${t.githubOrg}`);
