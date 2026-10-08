[Part 7/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

### `sandbox.ripgrep`

Point the sandbox at a ripgrep binary of your own instead of the one Claude Code uses, for example when your platform needs a differently built `rg`.

* **Scope**: [`User or managed`](#scopes)
* **Type**: object with `command`, the path to the ripgrep binary, and optional `args`, an array of arguments to prepend
* **Default**: unset, so the sandbox uses the same ripgrep binary as Claude Code. That is the bundled binary unless you set [`USE_BUILTIN_RIPGREP`](/docs/en/env-vars) to `0`

```json settings.json theme={null}
{
  "sandbox": {
    "ripgrep": {
      "command": "/usr/local/bin/rg"
    }
  }
}
```

### `sandbox.bwrapPath`

Point the sandbox at a bubblewrap binary installed outside `PATH`, such as a vendored copy on an air-gapped host. Claude Code uses the path both for the startup dependency check and when it wraps each sandboxed command.

* **Scope**: [`Managed`](#scopes). Claude Code reads it only from managed settings so that a user, project, or local file can't point the sandbox at a different binary.
* **Type**: string, an absolute path; Claude Code drops a relative path and falls back to `PATH` lookup
* **Default**: unset, so Claude Code finds `bwrap` on `PATH`

```json managed-settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "bwrapPath": "/opt/admin/bwrap"
  }
}
```

Linux and WSL2 only.

### `sandbox.socatPath`

Point the sandbox network proxy at a `socat` binary installed outside `PATH`.

* **Scope**: [`Managed`](#scopes)
* **Type**: string, an absolute path; Claude Code drops a relative path and falls back to `PATH` lookup
* **Default**: unset, so Claude Code finds `socat` on `PATH`

```json managed-settings.json theme={null}
{
  "sandbox": {
    "enabled": true,
    "socatPath": "/opt/admin/socat"
  }
}
```

Linux and WSL2 only.

### `sandbox.credentials`

Declare the credential files and environment variables to [protect from sandboxed commands](/docs/en/sandboxing#protect-credentials). Each entry names a file `path` or a variable `name` and a `mode`: `deny` hides the credential inside the sandbox, and `mask` shows sandboxed commands a placeholder while the [sandbox proxy](/docs/en/sandboxing#mask-credentials) substitutes the real value on outbound requests. Claude Code protects only the entries you list; there is no built-in credential deny list.

* **Scope**: [`Any file`](#scopes). Claude Code honors `mask` entries, `allowPlaintextInject`, `awsPairs`, and `sigv4` only from user settings, managed settings, and the `--settings` flag.
* **Type**: object with `files`, `envVars`, `allowPlaintextInject`, `awsPairs`, and `sigv4`
* **Default**: unset, so no credentials are protected

This hides your AWS credentials file and removes `GITHUB_TOKEN` from sandboxed commands:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "files": [{ "path": "~/.aws/credentials", "mode": "deny" }],
      "envVars": [{ "name": "GITHUB_TOKEN", "mode": "deny" }]
    }
  }
}
```

The `deny` file protection is part of the filesystem layer, so it doesn't apply when you [disable filesystem isolation](/docs/en/sandboxing#disable-filesystem-isolation); the environment variable protection still does.

#### Invalid credential entries in managed settings

When a managed `sandbox.credentials` entry fails validation, Claude Code keeps protecting the credential where it can:

* An entry in `files` or `envVars` that still has a valid `path` or `name` and a `mode` of `mask` or `deny`, such as one whose `extract` pattern has no capturing group, is degraded to `mode: "deny"` with a warning, so the credential stays blocked, not masked, until you fix the entry. A degraded `files` entry pins [`filesystem.disabled`](/docs/en/sandboxing#disable-filesystem-isolation) like an explicit `deny` entry, and the warning notes that its read block isn't enforced if managed settings turn filesystem isolation off.
* An entry with an unknown `mode` or an invalid `path` or `name` is stripped.
* Each case warns; whether an entry is degraded or stripped, the remaining valid entries are still enforced, and a wholly invalid `credentials` value is dropped while the rest of `sandbox` still applies.

Applies in v2.1.191 and later; before v2.1.221, every invalid entry was stripped. For the other managed keys with per-field handling, see [Invalid entries in managed settings](/docs/en/managed-settings#invalid-entries-in-managed-settings).

### `sandbox.credentials.files`

Protect credential files or directories from sandboxed commands. With `"mode": "deny"`, Claude Code blocks reads of the path inside the sandbox, the same read block as [`sandbox.filesystem.denyRead`](#sandbox-filesystem-denyread). With `"mode": "mask"`, sandboxed commands on Linux and WSL2 read a sentinel copy of the file, and the sandbox proxy substitutes the real value on outbound requests to that entry's `injectHosts`; on macOS the file is unreadable inside the sandbox instead. `"mode": "mask"` requires Claude Code v2.1.221 or later.

* **Scope**: [`Any file`](#scopes). Claude Code drops `mask` entries from project `.claude/settings.json` and local `.claude/settings.local.json`.
* **Type**: array of objects, each with `path` and a `mode` of `"deny"` or `"mask"`, plus the optional [mask fields for files](#mask-fields-for-files)
* **Default**: unset, so no credential files are protected

This hides your AWS credentials file and masks the `gh` hosts file, substituting the real value only on requests to `api.github.com`:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "files": [
        { "path": "~/.aws/credentials", "mode": "deny" },
        { "path": "~/.config/gh/hosts.yml", "mode": "mask", "injectHosts": ["api.github.com"] }
      ]
    }
  }
}
```

Paths use the same [prefixes](#sandbox-path-prefixes) as the `sandbox.filesystem.*` settings, and Claude Code merges the arrays from every settings scope the session loads. [Protect credentials](/docs/en/sandboxing#protect-credentials) covers what still applies from sources you exclude with `--setting-sources`. `mask` entries require Claude Code v2.1.221 or later.

`mask` substitution runs only through the sandbox proxy, so set [`sandbox.network.tlsTerminate`](#sandbox-network-tlsterminate), or [`allowPlaintextInject`](#sandbox-credentials-allowplaintextinject) for plain-HTTP test networks. `mask` applies to a single file, so list each credential file individually. Claude Code accepts but ignores the `mask` fields on a `deny` entry. [Mask credentials](/docs/en/sandboxing#mask-credentials) covers which settings sources are honored, and [Mask credential files](/docs/en/sandboxing#mask-credential-files) covers when an entry falls back to `deny`.

<span id="sandbox-credentials-files-extract" />

<span id="sandbox-credentials-files-onextractnomatch" />

<span id="sandbox-credentials-files-decode" />

<span id="sandbox-credentials-files-maskclaims" />

<span id="sandbox-credentials-files-maskduplicates" />

<span id="sandbox-credentials-files-injecthosts" />

#### Mask fields for files

A `mask` entry accepts these optional fields. Without `extract` or `decode`, Claude Code replaces the entire file content with one sentinel. On macOS with filesystem isolation on, Claude Code applies a `mask` entry as `deny` before `extract` or `decode` runs; see [Mask credential files](/docs/en/sandboxing#mask-credential-files).

| Field | Type | What it does |
| :- | :- | :- |
| `extract` | string, a regular expression with at least one capturing group | Mask only the text captured by group 1 of each match, so the rest of the file stays parseable. With `decode` also set, Claude Code checks each capture as a possible JWT instead of replacing it outright. Requires v2.1.221 or later |
| `onExtractNoMatch` | `"warn"`, `"deny"`, or `"error"`; default `"warn"` | What happens when `extract` or `decode` finds nothing to mask. `warn` leaves the file readable as-is inside the sandbox, `deny` makes it unreadable, and `error` stops sandbox setup until you fix the configuration. Claude Code treats `deny` as `error` when the read block wouldn't be enforced, because you [disable filesystem isolation](/docs/en/sandboxing#disable-filesystem-isolation) or a [`sandbox.filesystem.allowRead`](#sandbox-filesystem-allowread) entry re-opens the path. Requires v2.1.221 or later; the `decode` case requires v2.1.224 or later |
| `decode` | the string `"jwt"` | Find JSON Web Tokens (JWTs) in the file, with a built-in pattern or with `extract` when set, verify each candidate, and replace it with a structurally valid fake token, so code inside the sandbox that decodes the token keeps working. When no candidate verifies, `onExtractNoMatch` governs the outcome. Requires v2.1.224 or later |
| `maskClaims` | array of strings, at least one claim name; requires `decode` | Mask only the named top-level payload claims inside each verified JWT and rebuild the token around the modified payload, so the other claims stay readable. When no named claim matches, `onExtractNoMatch` governs the outcome. Requires v2.1.224 or later |
| `maskDuplicates` | Boolean, default `false` | Also replace verbatim copies of each masked value elsewhere in the file, such as a secret pasted into a comment. Claude Code matches raw substrings, so reserve it for long, high-entropy secrets. Consulted only when `extract` or `decode` is set. Requires v2.1.221 or later |
| `injectHosts` | array of strings, each a host that [`sandbox.network.allowedDomains`](#sandbox-network-alloweddomains) also admits | Narrow the hosts where the sandbox proxy substitutes the real value. When unset, the proxy substitutes it on requests to every host in `sandbox.network.allowedDomains`. Requires v2.1.221 or later |

This masks only the `oauth_token` value in the `gh` hosts file, replaces every other copy of it in the file, makes the file unreadable if the pattern matches nothing, and substitutes the real token only on requests to `api.github.com`:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "files": [
        {
          "path": "~/.config/gh/hosts.yml",
          "mode": "mask",
          "extract": "oauth_token:\\s*(\\S+)",
          "maskDuplicates": true,
          "onExtractNoMatch": "deny",
          "injectHosts": ["api.github.com"]
        }
      ]
    }
  }
}
```

### `sandbox.credentials.envVars`

Protect environment variables from sandboxed commands. With `"mode": "deny"`, Claude Code removes the variable from the environment of sandboxed commands. With `"mode": "mask"`, sandboxed commands see a per-session sentinel value, and the sandbox proxy substitutes the real value on outbound requests to that entry's `injectHosts`, so tools such as `gh` and `npm` keep authenticating without ever holding the real credential.

* **Scope**: [`Any file`](#scopes). Claude Code drops `mask` entries from project `.claude/settings.json` and local `.claude/settings.local.json`.
* **Type**: array of objects, each with `name` and a `mode` of `"deny"` or `"mask"`, plus the optional [mask fields for environment variables](#mask-fields-for-environment-variables)
* **Default**: unset, so no environment variables are protected

This removes `NPM_TOKEN` from sandboxed commands and masks `GITHUB_TOKEN`, substituting the real value only on requests to `api.github.com`:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "envVars": [
        { "name": "NPM_TOKEN", "mode": "deny" },
        { "name": "GITHUB_TOKEN", "mode": "mask", "injectHosts": ["api.github.com"] }
      ]
    }
  }
}
```

The `name` must start with a letter or underscore and contain only letters, digits, and underscores. Claude Code merges the arrays from every settings scope the session loads, and applies `deny` when the same variable appears with both modes. [Protect credentials](/docs/en/sandboxing#protect-credentials) covers what still applies from sources you exclude with `--setting-sources`.

`mask` substitution runs only through the sandbox proxy, so set [`sandbox.network.tlsTerminate`](#sandbox-network-tlsterminate), or [`allowPlaintextInject`](#sandbox-credentials-allowplaintextinject) for plain-HTTP test networks; see [Mask credentials](/docs/en/sandboxing#mask-credentials). Claude Code accepts but ignores the `mask` fields on a `deny` entry.

<span id="sandbox-credentials-envvars-extract" />

<span id="sandbox-credentials-envvars-onextractnomatch" />

<span id="sandbox-credentials-envvars-decode" />

<span id="sandbox-credentials-envvars-maskclaims" />

<span id="sandbox-credentials-envvars-injecthosts" />

#### Mask fields for environment variables

A `mask` entry accepts these optional fields. Without `extract` or `decode`, Claude Code replaces the entire value with one sentinel. `extract` and `decode` can't be combined on the same entry.

| Field | Type | What it does |
| :- | :- | :- |
| `extract` | string, a regular expression with at least one capturing group | Mask only the text captured by group 1 of each match, such as the password inside a `DATABASE_URL` connection string, so the rest of the value stays parseable. Requires v2.1.224 or later |
| `onExtractNoMatch` | `"warn"`, `"deny"`, or `"error"`; default `"warn"`. On an entry with `decode`, only `"warn"` is accepted | What happens when `extract` matches nothing. `warn` passes the variable through unmasked, `deny` unsets it inside the sandbox, and `error` stops sandbox setup until you fix the configuration. Requires v2.1.224 or later |
| `decode` | the string `"jwt"` | Verify the whole value is a JWT and replace it with a structurally valid fake token, so code inside the sandbox that decodes the token keeps working; the proxy substitutes the whole real token on egress. A value that doesn't verify passes through unmasked with a warning. Requires v2.1.224 or later |
| `maskClaims` | array of strings, at least one claim name; requires `decode` | Mask only the named top-level payload claims inside the decoded JWT and rebuild the token around the modified payload, so the other claims stay readable. When no named claim matches, the variable passes through unmasked with a warning. Requires v2.1.224 or later |
| `injectHosts` | array of strings, each a host that [`sandbox.network.allowedDomains`](#sandbox-network-alloweddomains) also admits | Narrow the hosts where the sandbox proxy substitutes the real value. When unset, the proxy substitutes it on requests to every host in `sandbox.network.allowedDomains`. Write an IPv6 destination as the bare compressed address, such as `"::1"`, not the bracketed form; see [IPv6 destinations in `injectHosts`](/docs/en/sandboxing#ipv6-destinations-in-injecthosts) |

This masks only the password inside `DATABASE_URL`, unsets the variable if the pattern matches nothing, and masks a JWT in `SERVICE_JWT` while leaving every claim except `api_key` readable:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "envVars": [
        {
          "name": "DATABASE_URL",
          "mode": "mask",
          "extract": "://[^:]+:([^@]+)@",
          "onExtractNoMatch": "deny"
        },
        {
          "name": "SERVICE_JWT",
          "mode": "mask",
          "decode": "jwt",
          "maskClaims": ["api_key"]
        }
      ]
    }
  }
}
```

### `sandbox.credentials.allowPlaintextInject`

Allow `mask` substitution on plain HTTP requests as well as TLS-terminated HTTPS. On plain HTTP the upstream identity is unverified and the credential travels in cleartext, so leave this off outside trusted test networks.

* **Scope**: [`User or managed`](#scopes)
* **Type**: Boolean
  * `true`: Claude Code allows `mask` substitution on plain HTTP requests as well as TLS-terminated HTTPS
  * `false`: Claude Code allows `mask` substitution only on TLS-terminated HTTPS
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "allowPlaintextInject": true
    }
  }
}
```

### `sandbox.credentials.awsPairs`

Group masked environment variables that form one AWS credential for [SigV4 re-signing](/docs/en/sandboxing#re-sign-aws-requests) when your credential lives in variables with non-standard names. Claude Code links the conventional `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` trio automatically when you mask their whole values, so you need this key only for other names. Requires Claude Code v2.1.224 or later.

* **Scope**: [`User or managed`](#scopes)
* **Type**: array of objects, each with `accessKeyIdVar`, `secretAccessKeyVar`, and optionally `sessionTokenVar`, naming `sandbox.credentials.envVars` entries
* **Default**: unset, so only the conventional trio is paired

This links three custom-named variables into one AWS credential for re-signing:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "awsPairs": [
        {
          "accessKeyIdVar": "MY_KEY_ID",
          "secretAccessKeyVar": "MY_SECRET_KEY",
          "sessionTokenVar": "MY_SESSION_TOKEN"
        }
      ]
    }
  }
}
```

Each named variable must be a whole-value `mask` entry in [`sandbox.credentials.envVars`](#sandbox-credentials-envvars), without `extract` or `decode`, and can fill only one slot across all pairs. These rules also apply:

* The proxy re-signs requests on the hosts listed in the access key ID entry's `injectHosts`
* When `sessionTokenVar` is set, the proxy sends the real token as `x-amz-security-token` on re-signed requests
* Naming any of the conventional variables in a pair replaces the automatic pairing

### `sandbox.credentials.sigv4`

Choose what the sandbox proxy does with AWS request forms it [can't re-sign](/docs/en/sandboxing#re-sign-aws-requests): `streaming` for aws-chunked streaming uploads, `presigned` for presigned URLs, and `sigv4a` for SigV4A asymmetric signatures. This applies only to requests signed with a masked pair's placeholder access key ID. Requires Claude Code v2.1.224 or later.

* **Scope**: [`User or managed`](#scopes)
* **Type**: object with `streaming`, `presigned`, and `sigv4a`, each one of:
  * `"deny"`: the proxy fails the request
  * `"passthrough"`: the proxy forwards the request signed with the masked placeholder, so the tool receives AWS's own rejection
* **Default**: unset, so every form is `"deny"`

This forwards streaming uploads instead of failing them at the proxy:

```json settings.json theme={null}
{
  "sandbox": {
    "credentials": {
      "sigv4": {
        "streaming": "passthrough"
      }
    }
  }
}
```

With `deny`, the proxy fails the request. With `passthrough`, the proxy forwards the request with its signature computed from the masked placeholder, so AWS rejects it and the calling tool receives AWS's own response instead of a proxy error.

### `sandbox.network`

Control which hosts, ports, and sockets sandboxed commands can reach. The sandbox routes outbound traffic through a proxy that enforces these lists; see [Network isolation](/docs/en/sandboxing#network-isolation) for how the proxy decides and when it prompts.

* **Scope**: [`Any file`](#scopes). `strictAllowlist`, `allowManagedDomainsOnly`, and `tlsTerminate` are read from fewer sources, as their entries say.
* **Type**: object with the sub-keys below
* **Default**: unset, so no domains are pre-allowed and your permission mode decides [what happens to each new host](/docs/en/sandboxing#hosts-outside-your-allowed-domains)

This pre-allows GitHub and npm, blocks `uploads.github.com`, and lets commands bind to localhost:

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "deniedDomains": ["uploads.github.com"],
      "allowLocalBinding": true
    }
  }
}
```

Claude Code merges the array sub-keys across settings scopes, so a project can add domains to your user list unless a [repository lock](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox) applies. `WebFetch(domain:...)` allow and deny [permission rules](/docs/en/sandboxing#permission-rules) feed the same allow and deny lists.

### `sandbox.network.allowUnixSockets`

List the Unix socket paths sandboxed commands can connect to on macOS. Claude Code ignores this list on Linux and WSL2, where the seccomp filter can't inspect socket paths; use [`allowAllUnixSockets`](#sandbox-network-allowallunixsockets) there instead.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: array of strings, each a socket path
* **Default**: unset, so the macOS sandbox blocks every Unix socket

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowUnixSockets": ["~/.ssh/agent-socket"]
    }
  }
}
```

A socket path can grant broad access: allowing `/var/run/docker.sock`, for example, lets a sandboxed command control the Docker daemon. See [Security limitations](/docs/en/sandboxing#security-limitations).

### `sandbox.network.allowAllUnixSockets`

Let sandboxed commands connect to every Unix socket. On Linux and WSL2, the sandbox's [seccomp filter](/docs/en/sandboxing#set-up-linux-and-wsl2) blocks `socket(AF_UNIX, ...)` calls, so this is the only way to permit Unix sockets there. When the filter is missing, which `/sandbox` reports on its Dependencies tab, the sandbox doesn't block Unix-socket calls. See [Set up Linux and WSL2](/docs/en/sandboxing#set-up-linux-and-wsl2) for where the filter comes from.

* **Scope**: [`Any file`](#scopes), with [limits on project and local settings](/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
* **Type**: Boolean
  * `true`: sandboxed commands can connect to every Unix socket
  * `false`: the sandbox blocks Unix-socket connections: on macOS except the paths in `allowUnixSockets`, and on Linux and WSL2 through the seccomp filter when it's present
* **Default**: `false`

```json settings.json theme={null}
{
  "sandbox": {
    "network": {
      "allowAllUnixSockets": true
    }
  }
}
```

On WSL2, `true` also reopens the interop socket that launches Windows binaries such as `cmd.exe` and `powershell.exe`.
