[Part 3/3 of https://code.claude.com/docs/en/cloud-environments.md, fetched 2026-10-08]

### Script requirements

A setup script has three constraints to write around:

* **Exit zero**: if the script exits non-zero, the session fails to start. Append `|| true` to non-critical commands so an intermittent install failure doesn't block the session.
* **Finish within five minutes**: keep the script's total runtime under roughly five minutes so the [environment cache](#environment-caching) can build. When setup takes longer than that, the environment isn't cached. Run independent installs in parallel with `&` and `wait`, and move any single download that won't fit into a [SessionStart hook](#setup-scripts-vs-sessionstart-hooks) that launches it in the background. If new sessions stall or fail during setup, see [New sessions hang or time out during setup](/docs/en/web-quickstart#new-sessions-hang-or-time-out-during-setup).
* **Network access for installs**: package installs need to reach registries. The default **Trusted** level covers [common package registries](#default-allowed-domains) including npm, PyPI, RubyGems, and crates.io; with **None** network access, installs fail.

### Environment caching

The setup script runs the first time you start a session in an environment. When setup completes within [roughly five minutes](#script-requirements), Anthropic snapshots the filesystem and reuses that snapshot as the starting point for later sessions. New sessions start with your dependencies, tools, and Docker images already on disk, and skip the setup script step. This keeps startup fast even when the script installs large toolchains or pulls container images. If setup takes longer than roughly five minutes, the environment isn't cached.

The cache is a filesystem snapshot, so it keeps what the setup script writes to disk and loses anything that was only running. Packages you install, Docker images you pull, and files you write all carry over. A database the script started, a `docker compose up` stack, or any other background process doesn't; start those per session by asking Claude or with a [SessionStart hook](#setup-scripts-vs-sessionstart-hooks).

The setup script runs again to rebuild the cache when you change the environment's setup script or allowed network hosts, and when the cache reaches its expiry after roughly seven days. In an Anthropic-hosted environment, the setup script doesn't run when a session's VM is [restored after being idle](#set-environment-variables), so a change to the script reaches an existing session only when its VM was [reclaimed](/docs/en/claude-code-on-the-web#environment-expired) and is rebuilt. To apply a change right away, run the commands in the session or start a new session.

You don't need to enable caching or manage snapshots yourself.

### Setup scripts vs. SessionStart hooks

Use a setup script to provision the VM itself: toolchains and CLI tools that aren't [pre-installed](#installed-tools). Use a [SessionStart hook](/docs/en/hooks#sessionstart) for project setup that should run everywhere, cloud and local, like `npm install`.

Setup scripts and SessionStart hooks run in a fixed order when a cloud session starts. The table compares where you configure them, when they run, and where they run.

| | Setup scripts | SessionStart hooks |
| - | - | - |
| **Where you configure them** | The environment dialog at [claude.ai/code](https://claude.ai/code), plus the **Cloud environments** admin page for [shared environments](#organization-shared-environments) | A [settings file](/docs/en/settings#where-settings-live) such as your repo's `.claude/settings.json`; see [What carries over from your setup](#what-carries-over-from-your-setup) for which files reach a cloud session |
| **When they run** | Before Claude Code launches, skipped when a [cached environment](#environment-caching) exists | After Claude Code launches, on every session including resumed |
| **Where they run** | Cloud sessions only | Local and cloud sessions |

If you have SessionStart hooks in your user-level `~/.claude/settings.json`, don't expect them in the cloud. User-level settings stay on your machine. Which other hooks run depends on where the session runs:

* **Anthropic-hosted environment**: Claude Code runs hooks from the repository and from your organization's [server-managed settings](/docs/en/server-managed-settings). [Claude Tag](https://claude.com/docs/claude-tag/overview) sessions don't receive server-managed settings, so hooks from server-managed settings don't run there.
* **[Self-hosted environment](/docs/en/self-hosted-environments-configuration#permissions-and-tool-approval)**: Claude Code also runs the hooks the operator seeded from the runner host's `~/.claude/`, and the hooks in the runner image's managed settings file when that file is one of the [managed sources Claude Code applies](/docs/en/managed-settings#how-claude-code-combines-managed-sources).

### Install dependencies with a SessionStart hook

To install dependencies only in cloud sessions, pair a SessionStart hook with a script that checks where it's running.

First, add a SessionStart hook to your repo's `.claude/settings.json`. This configuration tells Claude Code to run `scripts/install_pkgs.sh` from your repository whenever a session starts or resumes:

```json theme={null}
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/scripts/install_pkgs.sh"
          }
        ]
      }
    ]
  }
}
```

The `matcher` limits the hook to the `startup` and `resume` events, and `$CLAUDE_PROJECT_DIR` resolves to the repository root, so the hook finds the script regardless of the session's working directory.

Next, create the script at `scripts/install_pkgs.sh`. It exits immediately outside the cloud, then installs your dependencies:

```bash theme={null}
#!/bin/bash

if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

npm install
pip install -r requirements.txt
exit 0
```

The `CLAUDE_CODE_REMOTE` check is what scopes the install to cloud sessions: the session VM's environment carries that variable as `true`, it's never `true` locally, so on your laptop the script exits before installing anything.

Together, the two files give every cloud session a fresh `npm install` and `pip install` at startup while leaving local sessions untouched.

#### Limitations in cloud sessions

SessionStart hooks behave the same in the cloud as locally, with these caveats:

* **One repository per session**: a session with several repositories doesn't load hooks from any repository's `.claude/settings.json`, so a SessionStart hook you define there doesn't run. Install dependencies for those sessions with a [setup script](#setup-scripts) instead.
* **No cloud-only scoping**: hooks run in both local and cloud sessions. To skip local execution, exit early unless the `CLAUDE_CODE_REMOTE` environment variable is `true`, the way the [dependency install script](#install-dependencies-with-a-sessionstart-hook) does.
* **Requires network access**: install commands need to reach package registries. If your environment uses **None** network access, these hooks fail. The [default allowlist](#default-allowed-domains) under **Trusted** covers npm, PyPI, RubyGems, and crates.io.
* **Proxy compatibility**: in Anthropic-hosted environments, all outbound traffic passes through a [security proxy](#security-proxy), and some package managers don't work correctly with it; Bun is a known example. In a [self-hosted environment](/docs/en/self-hosted-environments-deploy#default-deny-egress), outbound traffic goes through your own network boundary instead.
* **Adds startup latency**: hooks run each time a session starts or resumes, unlike setup scripts which benefit from [environment caching](#environment-caching). Keep install scripts fast by checking whether dependencies are already present before reinstalling.

To customize the base image, use a setup script to install what you need on top of the [provided image](#installed-tools), or run your own image as a container alongside Claude with `docker compose`. Replacing the base image entirely isn't supported yet.

## Default allowed domains

With **Trusted** network access, sessions can reach the following domains by default. Domains marked with `*` indicate wildcard subdomain matching, so `*.gcr.io` allows any subdomain of `gcr.io`.

<AccordionGroup>
  <Accordion title="Anthropic services">
    * api.anthropic.com
    * docs.claude.com
    * platform.claude.com
    * code.claude.com
    * claude.ai
    * claude.com
    * support.claude.com
    * anthropic.com
    * [www.anthropic.com](http://www.anthropic.com)
  </Accordion>

  <Accordion title="Version control">
    * github.com
    * [www.github.com](http://www.github.com)
    * api.github.com
    * npm.pkg.github.com
    * raw\.githubusercontent.com
    * pkg-npm.githubusercontent.com
    * objects.githubusercontent.com
    * release-assets.githubusercontent.com
    * codeload.github.com
    * avatars.githubusercontent.com
    * camo.githubusercontent.com
    * gist.github.com
    * gitlab.com
    * [www.gitlab.com](http://www.gitlab.com)
    * registry.gitlab.com
    * bitbucket.org
    * [www.bitbucket.org](http://www.bitbucket.org)
    * api.bitbucket.org
  </Accordion>

  <Accordion title="Container registries">
    * registry-1.docker.io
    * auth.docker.io
    * index.docker.io
    * hub.docker.com
    * [www.docker.com](http://www.docker.com)
    * production.cloudflare.docker.com
    * production.cloudfront.docker.com
    * download.docker.com
    * gcr.io
    * \*.gcr.io
    * ghcr.io
    * mcr.microsoft.com
    * \*.data.mcr.microsoft.com
    * public.ecr.aws
  </Accordion>

  <Accordion title="Cloud platforms">
    * cloud.google.com
    * accounts.google.com
    * gcloud.google.com
    * \*.googleapis.com
    * storage.googleapis.com
    * compute.googleapis.com
    * container.googleapis.com
    * azure.com
    * portal.azure.com
    * microsoft.com
    * [www.microsoft.com](http://www.microsoft.com)
    * \*.microsoftonline.com
    * packages.microsoft.com
    * dotnet.microsoft.com
    * dot.net
    * visualstudio.com
    * dev.azure.com
    * \*.amazonaws.com
    * \*.api.aws
    * oracle.com
    * [www.oracle.com](http://www.oracle.com)
    * java.com
    * [www.java.com](http://www.java.com)
    * java.net
    * [www.java.net](http://www.java.net)
    * download.oracle.com
    * yum.oracle.com
    * \*.r2.cloudflarestorage.com
  </Accordion>

  <Accordion title="JavaScript and Node package managers">
    * registry.npmjs.org
    * [www.npmjs.com](http://www.npmjs.com)
    * [www.npmjs.org](http://www.npmjs.org)
    * npmjs.com
    * npmjs.org
    * yarnpkg.com
    * registry.yarnpkg.com
    * jsr.io
    * npm.jsr.io
  </Accordion>

  <Accordion title="Python package managers">
    * pypi.org
    * [www.pypi.org](http://www.pypi.org)
    * files.pythonhosted.org
    * pythonhosted.org
    * test.pypi.org
    * pypi.python.org
    * pypa.io
    * [www.pypa.io](http://www.pypa.io)
  </Accordion>

  <Accordion title="Ruby package managers">
    * rubygems.org
    * [www.rubygems.org](http://www.rubygems.org)
    * api.rubygems.org
    * index.rubygems.org
    * ruby-lang.org
    * [www.ruby-lang.org](http://www.ruby-lang.org)
    * rubyforge.org
    * [www.rubyforge.org](http://www.rubyforge.org)
    * rubyonrails.org
    * [www.rubyonrails.org](http://www.rubyonrails.org)
    * rvm.io
    * get.rvm.io
  </Accordion>

  <Accordion title="Rust package managers">
    * crates.io
    * [www.crates.io](http://www.crates.io)
    * index.crates.io
    * static.crates.io
    * rustup.rs
    * static.rust-lang.org
    * [www.rust-lang.org](http://www.rust-lang.org)
  </Accordion>

  <Accordion title="Go package managers">
    * proxy.golang.org
    * sum.golang.org
    * index.golang.org
    * golang.org
    * [www.golang.org](http://www.golang.org)
    * goproxy.io
    * pkg.go.dev
  </Accordion>

  <Accordion title="JVM package managers">
    * maven.org
    * repo.maven.org
    * central.maven.org
    * repo1.maven.org
    * repo.maven.apache.org
    * maven.google.com
    * jcenter.bintray.com
    * gradle.org
    * [www.gradle.org](http://www.gradle.org)
    * services.gradle.org
    * plugins.gradle.org
    * plugins-artifacts.gradle.org
    * kotlinlang.org
    * [www.kotlinlang.org](http://www.kotlinlang.org)
    * spring.io
    * repo.spring.io
  </Accordion>

  <Accordion title="Other package managers">
    * packagist.org (PHP Composer)
    * [www.packagist.org](http://www.packagist.org)
    * repo.packagist.org
    * nuget.org (.NET NuGet)
    * [www.nuget.org](http://www.nuget.org)
    * api.nuget.org
    * pub.dev (Dart/Flutter)
    * api.pub.dev
    * hex.pm (Elixir/Erlang)
    * [www.hex.pm](http://www.hex.pm)
    * cpan.org (Perl CPAN)
    * [www.cpan.org](http://www.cpan.org)
    * metacpan.org
    * [www.metacpan.org](http://www.metacpan.org)
    * api.metacpan.org
    * cocoapods.org (iOS/macOS)
    * [www.cocoapods.org](http://www.cocoapods.org)
    * cdn.cocoapods.org
    * haskell.org
    * [www.haskell.org](http://www.haskell.org)
    * hackage.haskell.org
    * swift.org
    * [www.swift.org](http://www.swift.org)
  </Accordion>

  <Accordion title="Linux distributions">
    * archive.ubuntu.com
    * security.ubuntu.com
    * ubuntu.com
    * [www.ubuntu.com](http://www.ubuntu.com)
    * \*.ubuntu.com
    * ppa.launchpad.net
    * launchpad.net
    * [www.launchpad.net](http://www.launchpad.net)
    * \*.nixos.org
  </Accordion>

  <Accordion title="Development tools and platforms">
    * dl.k8s.io (Kubernetes)
    * pkgs.k8s.io
    * k8s.io
    * [www.k8s.io](http://www.k8s.io)
    * releases.hashicorp.com (HashiCorp)
    * apt.releases.hashicorp.com
    * rpm.releases.hashicorp.com
    * archive.releases.hashicorp.com
    * hashicorp.com
    * [www.hashicorp.com](http://www.hashicorp.com)
    * repo.anaconda.com (Anaconda/Conda)
    * conda.anaconda.org
    * anaconda.org
    * [www.anaconda.com](http://www.anaconda.com)
    * anaconda.com
    * continuum.io
    * apache.org (Apache)
    * [www.apache.org](http://www.apache.org)
    * archive.apache.org
    * downloads.apache.org
    * eclipse.org (Eclipse)
    * [www.eclipse.org](http://www.eclipse.org)
    * download.eclipse.org
    * nodejs.org (Node.js)
    * [www.nodejs.org](http://www.nodejs.org)
    * developer.apple.com
    * developer.android.com
    * pkg.stainless.com
    * binaries.prisma.sh
  </Accordion>

  <Accordion title="Cloud services and monitoring">
    * http-intake.logs.datadoghq.com
    * \*.datadoghq.com
    * \*.datadoghq.eu
    * api.honeycomb.io
  </Accordion>

  <Accordion title="Content delivery and mirrors">
    * sourceforge.net
    * \*.sourceforge.net
    * packagecloud.io
    * \*.packagecloud.io
    * fonts.googleapis.com
    * fonts.gstatic.com
  </Accordion>

  <Accordion title="Schema and configuration">
    * json-schema.org
    * [www.json-schema.org](http://www.json-schema.org)
    * json.schemastore.org
    * [www.schemastore.org](http://www.schemastore.org)
  </Accordion>

  <Accordion title="Model Context Protocol">
    * \*.modelcontextprotocol.io
  </Accordion>
</AccordionGroup>

## Related resources

* [Cloud sessions reference](/docs/en/claude-code-on-the-web): start, manage, and share cloud sessions
* [Cloud sessions quickstart](/docs/en/web-quickstart): connect GitHub and start your first cloud session
* [Claude Tag](https://claude.com/docs/claude-tag/overview): sessions Claude starts from Slack run in the same environments
* [Routines](/docs/en/routines): scheduled runs use the same environments and network access levels
* [Remote Control](/docs/en/remote-control): run sessions on your own machine's network and files instead
* [Self-hosted environments](/docs/en/self-hosted-environments): run cloud sessions on your organization's own infrastructure
* [SessionStart hooks](/docs/en/hooks#sessionstart): repo-committed setup that runs in local and cloud sessions
* [Server-managed settings](/docs/en/server-managed-settings): organization policy delivered from the admin console
