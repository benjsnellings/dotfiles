/*
 * Playwright MCP init-page script for Midway (cookie-file mode).
 *
 * Loaded via `--init-page` on the Playwright MCP server. On every new page it
 * reads ~/.midway/cookie (Netscape format), de-duplicates, and injects the
 * cookies into the browser context so navigation to Midway-protected internal
 * sites is authenticated as the local user.
 *
 * Scope: works for DIRECT Midway sites (code.amazon.com, phonetool,
 * midway-auth, most builderhub) AND any federated/OIDC site whose IdP trusts
 * the injected amazon_enterprise_access (AEA) cookie on an *.aws.dev /
 * *.a2z.com / *.amazon.dev domain (e.g. the tunnels.lab.aws.dev tunnels).
 * Only Kerberos-gated sites (w.amazon.com via kerberizer) still fail — those
 * require MCS mode from @amzn/playwright-midway-auth.
 *
 * Refresh AEA cookies with `mwinit --refresh-aea` (~2h lifetime); a full
 * `mwinit -s -o` re-auth if the session itself lapsed (~20h).
 *
 * SECURITY: this grants the agent every internal access you have. Trusted
 * agents / controlled environments only.
 */

// Loaded by @playwright/mcp via `--init-page` as an ES module; it invokes the
// DEFAULT export. Must be ESM (`export default`), not CommonJS.
import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

function parseMidwayCookies(content) {
  const byKey = new Map();
  for (let line of content.split('\n')) {
    let httpOnly = false;
    if (line.startsWith('#HttpOnly_')) {
      httpOnly = true;
      line = line.slice('#HttpOnly_'.length);
    }
    if (line.trim() === '' || line.startsWith('#')) continue;

    const p = line.split('\t');
    if (p.length < 7) continue;

    const secure = p[3].toLowerCase() === 'true';
    const cookie = {
      domain: p[0],
      path: p[2],
      secure,
      expires: parseInt(p[4], 10) || -1,
      name: p[5],
      value: p[6],
      httpOnly,
      sameSite: secure ? 'None' : 'Lax',
    };
    // De-dup name+domain, keep latest expiry (refreshed files keep stale rows).
    const key = `${cookie.name}|${cookie.domain}`;
    const prev = byKey.get(key);
    if (!prev || cookie.expires > prev.expires) byKey.set(key, cookie);
  }
  return [...byKey.values()];
}

export default async ({ page }) => {
  const cookiePath = join(homedir(), '.midway', 'cookie');
  let content;
  try {
    content = readFileSync(cookiePath, 'utf-8');
  } catch {
    console.error(`[midway-init] ${cookiePath} not found — run \`mwinit\` to authenticate.`);
    return;
  }

  const cookies = parseMidwayCookies(content);
  await page.context().clearCookies();
  await page.context().addCookies(cookies);
  console.error(`[midway-init] injected ${cookies.length} Midway cookies`);
};
