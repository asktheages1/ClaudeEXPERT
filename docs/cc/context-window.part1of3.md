[Part 1/3 of https://code.claude.com/docs/en/context-window.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Explore the context window

> An interactive simulation of how Claude Code's context window fills during a session. See what loads automatically, what each file read costs, and when rules and hooks fire.

export const ContextWindow = () => {
  const MAX = 200000;
  const STARTUP_END = 0.2;
  {}
  const EVENTS = useMemo(() => [{}, {
    t: 0.015,
    kind: 'auto',
    label: 'System prompt',
    tokens: 4200,
    color: '#6B6964',
    vis: 'hidden',
    desc: 'Core instructions for behavior, tool use, and response formatting. Always loaded first. You never see it.',
    link: null
  }, {
    t: 0.035,
    kind: 'auto',
    label: 'Auto memory (MEMORY.md)',
    tokens: 680,
    color: '#E8A45C',
    vis: 'hidden',
    desc: "Claude's notes to itself from previous sessions: build commands it learned, patterns it noticed, mistakes to avoid. The first 200 lines or 25KB, whichever comes first, are loaded into the conversation context.",
    link: '/en/memory#auto-memory'
  }, {
    t: 0.06,
    kind: 'auto',
    label: 'Environment info',
    tokens: 280,
    color: '#6B6964',
    vis: 'hidden',
    desc: 'Working directory, platform, shell, OS version, and whether this is a git repo. Git branch, status, and recent commits load as a separate block.',
    link: null
  }, {
    t: 0.08,
    kind: 'auto',
    label: 'MCP tools (deferred)',
    tokens: 120,
    color: '#9B7BC4',
    vis: 'hidden',
    desc: 'MCP tool names listed so Claude knows what is available. By default, full schemas stay deferred and Claude loads specific ones on demand via tool search when a task needs them. Set `ENABLE_TOOL_SEARCH=auto` to load schemas upfront when they fit within 10% of the context window, or `ENABLE_TOOL_SEARCH=false` to load everything.',
    link: '/en/mcp#scale-with-mcp-tool-search'
  }, {
    t: 0.1,
    kind: 'auto',
    label: 'Skill descriptions',
    tokens: 450,
    color: '#D4A843',
    vis: 'hidden',
    noSurviveCompact: true,
    desc: 'One-line descriptions of available skills so Claude knows what it can invoke. Full skill content loads only when Claude actually uses one. Skills with `disable-model-invocation: true` are not in this list. They stay completely out of context until you invoke them with `/name`. Unlike the rest of the startup content, this listing is not re-injected after `/compact`. Only skills you actually invoked get preserved.',
    link: '/en/skills'
  }, {
    t: 0.12,
    kind: 'auto',
    label: '~/.claude/CLAUDE.md',
    tokens: 320,
    color: '#6A9BCC',
    vis: 'hidden',
    desc: 'Your global preferences. Applies to every project. Loaded alongside project instructions at the start of every conversation.',
    link: '/en/memory#choose-where-to-put-claude-md-files'
  }, {
    t: 0.14,
    kind: 'auto',
    label: 'Project CLAUDE.md',
    tokens: 1800,
    color: '#6A9BCC',
    vis: 'hidden',
    desc: 'Project conventions, build commands, architecture notes. The most important file you can create. Lives in your project root, so your whole team gets the same instructions.',
    tip: 'Keep it under 200 lines. Move reference content to skills or path-scoped rules so it only loads when needed.',
    link: '/en/memory'
  }, {}, {
    t: 0.22,
    kind: 'user',
    label: 'Your prompt',
    tokens: 45,
    color: '#558A42',
    vis: 'full',
    desc: '"Fix the auth bug where users get 401 after token refresh"',
    link: null
  }, {}, {
    t: 0.28,
    kind: 'claude',
    label: 'Read src/api/auth.ts',
    tokens: 2400,
    color: '#8A8880',
    vis: 'brief',
    restoredAfterCompact: true,
    desc: 'Main auth file. You see "Read auth.ts" in your terminal, but the 2,400 tokens of file content only Claude sees.',
    tip: 'File reads dominate context usage. Be specific in prompts ("fix the bug in auth.ts") so Claude reads fewer files. For research-heavy tasks, use a subagent.',
    link: null
  }, {
    t: 0.32,
    kind: 'claude',
    label: 'Read src/lib/tokens.ts',
    tokens: 1100,
    color: '#8A8880',
    vis: 'brief',
    restoredAfterCompact: true,
    desc: 'Following imports to the token module. Shown as a one-liner in your terminal.',
    link: null
  }, {
    t: 0.35,
    kind: 'auto',
    label: 'Rule: api-conventions.md',
    tokens: 380,
    color: '#4A9B8E',
    vis: 'brief',
    desc: 'This rule in `.claude/rules/` has a `paths:` pattern matching `src/api/**`. It loaded automatically when Claude read a file in that directory. You see "Loaded .claude/rules/api-conventions.md" in your terminal, but not the rule content.',
    link: '/en/memory#path-specific-rules'
  }, {
    t: 0.38,
    kind: 'claude',
    label: 'Read middleware.ts',
    tokens: 1800,
    color: '#8A8880',
    vis: 'brief',
    restoredAfterCompact: true,
    desc: 'Tracing the auth flow deeper.',
    link: null
  }, {
    t: 0.41,
    kind: 'claude',
    label: 'Read auth.test.ts',
    tokens: 1600,
    color: '#8A8880',
    vis: 'brief',
    restoredAfterCompact: true,
    desc: 'Checking existing tests for expected behavior.',
    link: null
  }, {
    t: 0.44,
    kind: 'auto',
    label: 'Rule: testing.md',
    tokens: 290,
    color: '#4A9B8E',
    vis: 'brief',
    desc: 'Another path-scoped rule, this one matching `*.test.ts` files. Triggered when Claude read auth.test.ts. Shown as a one-line "Loaded" notice.',
    link: '/en/memory#path-specific-rules'
  }, {
    t: 0.47,
    kind: 'claude',
    label: 'grep "refreshToken"',
    tokens: 600,
    color: '#A09E96',
    vis: 'brief',
    desc: 'Search results across the codebase. You see the command ran, not the full output.',
    link: null
  }, {}, {
    t: 0.53,
    kind: 'claude',
    label: "Claude's analysis",
    tokens: 800,
    color: '#D97757',
    vis: 'full',
    desc: 'Explains the bug: token invalidated too early in the rotation. This text appears in your terminal.',
    link: null
  }, {
    t: 0.57,
    kind: 'claude',
    label: 'Edit auth.ts',
    tokens: 400,
    color: '#D97757',
    vis: 'full',
    desc: 'Fixes the token rotation order. The diff appears in your terminal.',
    link: null
  }, {
    t: 0.59,
    kind: 'hook',
    label: 'Hook: prettier',
    tokens: 120,
    color: '#B8860B',
    vis: 'hidden',
    desc: 'A PostToolUse hook in `settings.json` runs prettier after every file edit and reports back via `hookSpecificOutput.additionalContext`. That field enters Claude\'s context. Plain stdout on exit 0 does not. It is written to the debug log only.',
    tip: 'Output JSON with `additionalContext` to send info to Claude. For PostToolUse hooks, exit code 2 surfaces stderr as an error but cannot block since the tool already ran. Output over 10,000 characters is saved to a file; Claude gets a preview and the file path instead.',
    link: '/en/hooks-guide'
  }, {
    t: 0.62,
    kind: 'claude',
    label: 'Edit auth.test.ts',
    tokens: 600,
    color: '#D97757',
    vis: 'full',
    desc: 'Adds a regression test for the fix. The diff appears in your terminal.',
    link: null
  }, {
    t: 0.64,
    kind: 'hook',
    label: 'Hook: prettier',
    tokens: 100,
    color: '#B8860B',
    vis: 'hidden',
    desc: 'The same hook fires again for the test file. Every matching tool event triggers it.',
    link: '/en/hooks-guide'
  }, {
    t: 0.67,
    kind: 'claude',
    label: 'npm test output',
    tokens: 1200,
    color: '#A09E96',
    vis: 'brief',
    desc: 'Runs the test suite. You see "Running npm test..." and the pass count, not the full 1,200 tokens of output.',
    link: null
  }, {
    t: 0.70,
    kind: 'claude',
    label: 'Summary',
    tokens: 400,
    color: '#D97757',
    vis: 'full',
    desc: '"Fixed token rotation. Added regression test. All tests pass."',
    link: null
  }, {}, {
    t: 0.72,
    kind: 'user',
    label: 'Your follow-up',
    tokens: 40,
    color: '#558A42',
    vis: 'full',
    desc: '"Use a subagent to research session timeout handling, then fix it"',
    tip: 'Follow-ups add to the same context. Delegating research to a subagent keeps large file reads out of your main window.',
    link: null
  }, {
    t: 0.79,
    kind: 'claude',
    label: 'Spawn research subagent',
    tokens: 80,
    color: '#D97757',
    vis: 'brief',
    desc: "Claude delegates the research to a subagent with a fresh, separate context window. It loads CLAUDE.md and the same MCP and skill setup, but starts without your conversation history or the main session's auto memory.",
    link: '/en/sub-agents'
  }, {
    t: 0.795,
    kind: 'sub',
    label: 'System prompt',
    tokens: 0,
    subTokens: 900,
    color: '#6B6964',
    vis: 'hidden',
    desc: "The subagent gets its own system prompt, shorter than the main session's. For the general-purpose agent, it's a brief prompt plus environment details. The main session's auto memory is not included. If a custom agent has memory: in its frontmatter, it loads its own separate MEMORY.md here instead.",
    link: '/en/sub-agents#enable-persistent-memory'
  }, {
    t: 0.80,
    kind: 'sub',
    label: 'Project CLAUDE.md (own copy)',
    tokens: 0,
    subTokens: 1800,
    color: '#6A9BCC',
    vis: 'hidden',
    desc: "The subagent loads CLAUDE.md too. Same file, same content, but it counts against the subagent's context, not yours. The built-in Explore and Plan agents skip this for a smaller context.",
    link: '/en/sub-agents'
  }, {
    t: 0.805,
    kind: 'sub',
    label: 'MCP tools + skills',
    tokens: 0,
    subTokens: 970,
    color: '#9B7BC4',
    vis: 'hidden',
    desc: "The subagent has access to the same MCP servers and skills. It gets most of the parent's tools, minus several that don't apply in a nested context, including plan-mode controls, background-task tools, and by default the Agent tool itself to prevent recursion.",
    link: '/en/sub-agents'
  }, {
    t: 0.81,
    kind: 'sub',
    label: 'Task prompt from main',
    tokens: 0,
    subTokens: 120,
    color: '#558A42',
    vis: 'hidden',
    desc: "Instead of a user prompt, the subagent receives the task Claude wrote for it: 'Research session timeout handling in this codebase.'",
    link: '/en/sub-agents'
  }, {
    t: 0.82,
    kind: 'sub',
    label: 'Read session.ts',
    tokens: 0,
    subTokens: 2200,
    color: '#8A8880',
    vis: 'hidden',
    desc: "Now the subagent does its work. This file read fills the subagent's context, not yours.",
    link: '/en/sub-agents'
  }, {
    t: 0.825,
    kind: 'sub',
    label: 'Read timeouts.ts',
    tokens: 0,
    subTokens: 800,
    color: '#8A8880',
    vis: 'hidden',
    desc: "Another file read in the subagent's separate context.",
    link: '/en/sub-agents'
  }, {
    t: 0.83,
    kind: 'sub',
    label: 'Read config/*.ts',
    tokens: 0,
    subTokens: 3100,
    color: '#8A8880',
    vis: 'hidden',
    desc: "The subagent can read as many files as it needs. None of this touches your main context.",
    link: '/en/sub-agents'
  }, {
    t: 0.85,
    kind: 'claude',
    label: 'Subagent returns summary',
    tokens: 420,
    color: '#D97757',
    vis: 'brief',
    desc: "Only the subagent's final text response comes back to your context, plus a small metadata trailer with token counts and duration. The subagent read 6,100 tokens of files. You got a 420-token result. That's the context savings.",
    link: '/en/sub-agents'
  }, {
    t: 0.86,
    kind: 'claude',
    label: "Claude's response",
    tokens: 1200,
    color: '#D97757',
    vis: 'full',
    desc: 'Analysis and fix for session timeouts. This text appears in your terminal.',
    link: null
  }, {}, {
    t: 0.875,
    kind: 'user',
    label: '!git status',
    tokens: 180,
    color: '#558A42',
    vis: 'full',
    desc: "You ran a shell command with the ! prefix to see which files Claude modified. The command and its output both enter context as part of your message. Useful for grounding Claude in command output without Claude running it.",
    link: '/en/interactive-mode#shell-mode-with-prefix'
  }, {
    t: 0.89,
    kind: 'user',
    label: '/commit-push',
    tokens: 620,
    color: '#558A42',
    vis: 'brief',
    restoredAfterCompact: true,
    desc: 'You invoked a skill that has `disable-model-invocation: true`. Its description was not in the skill index at startup, so it cost zero context until this moment. Now the full skill content loads and Claude follows its instructions to stage, commit, and push your changes. After `/compact`, Claude Code re-injects the body of each skill you invoked, capped at 5,000 tokens per skill.',
    tip: 'Set `disable-model-invocation: true` on skills with side effects like committing, deploying, or sending messages. They stay out of context entirely until you need them.',
    link: '/en/skills#control-who-invokes-a-skill'
  }, {}, {
    t: 0.93,
    kind: 'compact',
    label: '/compact',
    tokens: 0,
    color: '#D97757',
    vis: 'brief',
    desc: 'Replaces the conversation with a structured summary. You see a "Conversation compacted" message. The summarization happens without appearing in your terminal.',
    link: '/en/how-claude-code-works#the-context-window'
  }].filter(e => e.t !== undefined), []);
  const VIS_META = {
    hidden: {
      label: 'Invisible in your terminal',
      sub: 'This content does not appear in your terminal.'
    },
    brief: {
      label: 'One-liner in your terminal',
      sub: 'You see a brief mention, not the full content.'
    },
    full: {
      label: 'Shown in your terminal',
      sub: 'The actual content appears in your terminal.'
    }
  };
  {}
  const GATES = [{
    at: 0.18,
    kind: 'prompt',
    text: 'Fix the auth bug where users get 401 after token refresh',
    resumeTo: 0.22
  }, {
    at: 0.705,
    kind: 'prompt',
    text: 'Use a subagent to research session timeout handling, then fix it',
    resumeTo: 0.72
  }, {
    at: 0.865,
    kind: 'bang',
    text: '!git status',
    resumeTo: 0.875
  }, {
    at: 0.88,
    kind: 'slash',
    text: '/commit-push',
    resumeTo: 0.89
  }, {
    at: 0.90,
    kind: 'compact',
    text: '/compact',
    resumeTo: 1
  }];
  const KIND_META = {
    auto: {
      badge: 'auto',
      detail: 'Auto-loaded',
      badgeBg: 'rgba(94,93,89,0.15)',
      badgeColor: '#8A8880'
    },
    user: {
      badge: 'you',
      detail: 'You typed this',
      badgeBg: 'rgba(85,138,66,0.15)',
      badgeColor: '#6BA656'
    },
    claude: {
      badge: 'claude',
      detail: "Claude's work",
      badgeBg: 'rgba(217,119,87,0.12)',
      badgeColor: '#D97757'
    },
    hook: {
      badge: 'hook',
      detail: 'Hook (automatic)',
      badgeBg: 'rgba(184,134,11,0.15)',
      badgeColor: '#CCA020'
    },
    compact: {
      badge: 'compact',
      detail: 'Compaction',
      badgeBg: 'rgba(217,119,87,0.12)',
      badgeColor: '#D97757'
    },
    sub: {
      badge: 'subagent',
      detail: "In subagent's context",
      badgeBg: 'rgba(155,123,196,0.12)',
      badgeColor: '#9B7BC4'
    }
  };
  const LEGEND = [{
    c: '#6B6964',
    l: 'System'
  }, {
    c: '#6A9BCC',
    l: 'CLAUDE.md'
  }, {
    c: '#E8A45C',
    l: 'Memory'
  }, {
    c: '#D4A843',
    l: 'Skills'
  }, {
    c: '#9B7BC4',
    l: 'MCP'
  }, {
    c: '#4A9B8E',
    l: 'Rules'
  }, {
    c: '#558A42',
    l: 'You'
  }, {
    c: '#8A8880',
    l: 'Files'
  }, {
    c: '#A09E96',
    l: 'Output'
  }, {
    c: '#D97757',
    l: 'Claude'
  }, {
    c: '#B8860B',
    l: 'Hooks'
  }];
  const fmt = n => n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, '') + 'K' : n + '';
  const [time, setTime] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [hovIdx, setHovIdx] = useState(null);
  const [selIdx, setSelIdx] = useState(null);
  const [hovCat, setHovCat] = useState(null);
  const [gatesPassed, setGatesPassed] = useState(0);
  const [mounted, setMounted] = useState(false);
  const [hasInteracted, setHasInteracted] = useState(false);
  const lastRef = useRef(null);
  const scrollRef = useRef(null);
  const detailRef = useRef(null);
  useEffect(() => setMounted(true), []);
  const activeGate = GATES.find((g, i) => i >= gatesPassed && time >= g.at && time < g.resumeTo);
  useEffect(() => {
    if (!playing) return;
    let raf;
    let stopped = false;
    const tick = ts => {
      if (stopped) return;
      if (!lastRef.current) lastRef.current = ts;
      const dt = (ts - lastRef.current) / 1000;
      lastRef.current = ts;
      setTime(prev => {
        const next = prev + dt * 0.032;
        const gate = GATES.find((g, i) => i >= gatesPassed && next >= g.at && prev < g.resumeTo);
        if (gate) {
          stopped = true;
          setPlaying(false);
          return gate.at;
        }
        if (next >= 1) {
          stopped = true;
          setPlaying(false);
          return 1;
        }
        return next;
      });
      if (!stopped) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => {
      stopped = true;
      cancelAnimationFrame(raf);
      lastRef.current = null;
    };
  }, [playing, gatesPassed]);
  const sendPrompt = () => {
    if (!activeGate) return;
    const isCompact = activeGate.kind === 'compact';
    setGatesPassed(n => n + 1);
    setTime(activeGate.resumeTo);
    setSelIdx(null);
    setHovIdx(null);
    if (!isCompact) setPlaying(true);
  };
  const visibleCount = EVENTS.filter(e => e.t <= time).length;
  const preCompactVisible = useMemo(() => EVENTS.slice(0, visibleCount), [EVENTS, visibleCount]);
  const compactGateIdx = GATES.length - 1;
  const isCompacted = gatesPassed > compactGateIdx && preCompactVisible.some(e => e.kind === 'compact');
  const {visible, preCompactTotal} = useMemo(() => {
    const nonCompact = preCompactVisible.filter(e => e.kind !== 'compact');
    if (!isCompacted) {
      return {
        visible: preCompactVisible,
        preCompactTotal: 0
      };
    }
    {}
    const autoLoads = nonCompact.filter(e => e.kind === 'auto' && e.t < STARTUP_END && !e.noSurviveCompact);
    const restored = nonCompact.filter(e => e.restoredAfterCompact);
    const summarized = nonCompact.filter(e => e.t >= STARTUP_END && e.kind !== 'sub');
    const sumTokens = summarized.reduce((s, e) => s + e.tokens, 0);
    const summaryBlock = {
      t: STARTUP_END,
      kind: 'compact',
      label: 'Conversation summary',
      tokens: Math.round(sumTokens * 0.12),
      color: '#A09E96',
      vis: 'hidden',
      desc: `All ${summarized.length} conversation events condensed into one structured summary. The summary keeps: your requests and intent, key technical concepts, files examined or modified with important code snippets, errors and how they were fixed, pending tasks, and current work. It replaces the verbatim conversation: full tool outputs and intermediate reasoning are gone. Claude Code re-reads the files modified most recently and re-injects the skills you invoked, listed below. Claude can still reference the rest of the work but won't have the exact content.`,
      link: '/en/how-claude-code-works#the-context-window'
    };
    return {
      visible: [...autoLoads, summaryBlock, ...restored],
      preCompactTotal: nonCompact.reduce((s, e) => s + e.tokens, 0)
    };
  }, [preCompactVisible, isCompacted]);
  const {blocks, totalTokens} = useMemo(() => {
    const bl = visible.map((e, visIdx) => ({
      ...e,
      id: e.label + e.t,
      visIdx
    })).filter(e => e.tokens > 0 || e.label === 'Conversation summary');
    return {
      blocks: bl,
      totalTokens: bl.reduce((s, b) => s + b.tokens, 0)
    };
  }, [visible]);
  const subTotal = useMemo(() => visible.filter(e => e.kind === 'sub').reduce((s, e) => s + (e.subTokens || 0), 0), [visible]);
  useEffect(() => {
    if (!scrollRef.current) return;
    if (isCompacted) scrollRef.current.scrollTo({
      top: 0,
      behavior: 'smooth'
    }); else if (playing || activeGate) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [visible.length, !!activeGate, isCompacted]);
  const rootRef = useRef(null);
  const keyStateRef = useRef({});
  const [isFullscreen, setIsFullscreen] = useState(false);
  keyStateRef.current = {
    time,
    activeGate,
    sendPrompt,
    hasInteracted
  };
  useEffect(() => {
    const onFsChange = () => setIsFullscreen(!!document.fullscreenElement);
    document.addEventListener('fullscreenchange', onFsChange);
    return () => document.removeEventListener('fullscreenchange', onFsChange);
  }, []);
  const toggleFullscreen = () => {
    if (!rootRef.current) return;
    if (document.fullscreenElement) document.exitFullscreen(); else rootRef.current.requestFullscreen().catch(() => {});
  };
  useEffect(() => {
    const onKey = e => {
      const tag = e.target.tagName;
      if (tag === 'INPUT' || tag === 'BUTTON' || tag === 'TEXTAREA' || tag === 'SELECT' || e.target.isContentEditable) return;
      if (!rootRef.current) return;
      const rect = rootRef.current.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) return;
      if (rect.bottom < 0 || rect.top > window.innerHeight) return;
      if (e.code === 'Space') {
        const {time: t, activeGate: g, sendPrompt: send, hasInteracted: hi} = keyStateRef.current;
        if (!hi) return;
        e.preventDefault();
        if (t === 0) setPlaying(true); else if (g) send(); else if (t >= 1) {
          setTime(0);
          setGatesPassed(0);
          setSelIdx(null);
          setHovIdx(null);
          setPlaying(true);
        } else setPlaying(p => !p);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);
  const pct = totalTokens / MAX * 100;
  const barColor = pct > 75 ? '#D97757' : pct > 50 ? '#B8860B' : '#558A42';
  const activeIdx = selIdx !== null ? selIdx : hovIdx;
  const hovEvent = activeIdx !== null ? visible[activeIdx] : null;
  useEffect(() => {
    if (detailRef.current) detailRef.current.scrollTop = 0;
  }, [hovEvent]);
  const focusT = hovEvent ? hovEvent.t : time;
  const takeaway = isCompacted ? 'Compaction replaces the conversation with a structured summary. System prompt, CLAUDE.md, memory, and MCP tools reload automatically. Claude Code also re-reads up to five of the files modified most recently and re-injects the skills you invoked. The skill listing does not reload.' : focusT < STARTUP_END ? 'A lot loads before you type anything. CLAUDE.md, memory, skills, and MCP tools are all in context before your first prompt.' : focusT < 0.28 ? "Your prompt is tiny compared to what's already loaded. Most of Claude's context is project knowledge, not your words." : focusT < 0.50 ? 'Each file Claude reads grows the context. Path-scoped rules load automatically alongside matching files.' : focusT < 0.71 ? 'Hooks fire automatically on tool events. Output reaches Claude via additionalContext JSON. Exit code 2 surfaces stderr to Claude. Plain stdout on exit 0 goes to the debug log, not the transcript.' : focusT < 0.79 ? 'Follow-up questions keep building on the same context. Everything from earlier is still there.' : focusT < 0.87 ? "The subagent works in its own separate context window. None of its file reads touch yours. Only the final summary comes back." : focusT < 0.88 ? 'Bang commands run in your shell and prefix the output to your next message. Useful for grounding Claude in command results without it running them.' : focusT < 0.90 ? 'User-only skills stay out of context entirely until you invoke them. The skill index at startup only lists skills Claude can call on its own.' : '/compact summarizes the conversation to free space while keeping key information. In a real session, run it when context starts affecting performance or before a long new task.';
  const terminalView = isCompacted ? 'A "Conversation compacted" message, then a one-line "Read auth.ts" for each re-read file and "Skills restored (commit-push)". None of the content itself appears.' : focusT < STARTUP_END ? 'The input box, waiting for your first message. Everything above loads silently before you type anything.' : focusT < 0.28 ? 'Your prompt. Claude hasn\'t started working yet.' : focusT < 0.52 ? 'Your prompt and "Reading files...". Rules show as one-line "Loaded" notices, not their content.' : focusT < 0.72 ? "Claude's response and file diffs. Hooks fire silently. Tool output like npm test shows as a brief summary, not the full content." : focusT < 0.79 ? 'Your follow-up prompt.' : focusT < 0.86 ? "A brief notice that a subagent is working, then its result. You don't see the subagent's individual file reads." : focusT < 0.90 ? "Claude's response, your git status output, and the commit-push skill running." : 'Your full conversation. /compact is available to run.';
  const mono = 'var(--font-mono, ui-monospace, SFMono-Regular, Menlo, monospace)';
  const renderWithCode = s => s.split('`').map((part, i) => i % 2 === 1 ? <code key={i} style={{
    fontFamily: mono,
    fontSize: '0.92em',
    background: 'var(--cw-track)',
    padding: '1px 4px',
    borderRadius: 3
  }}>{part}</code> : part);
  if (!mounted) return null;
  return <>
    <div className="cw-mobile-fallback">
      This interactive timeline works best on a larger screen. See <a href="#what-the-timeline-shows" style={{
    color: '#D97757'
  }}>the written breakdown below</a> for the same concepts.
    </div>
    <div className="cw-root" ref={rootRef} onClickCapture={() => setHasInteracted(true)} style={isFullscreen ? {
    height: '100vh',
    borderRadius: 0,
    display: 'flex',
    flexDirection: 'column'
  } : {}}>
      <style>{`
        .cw-root {
          --cw-bg: #FAFAF8;
          --cw-text: #1A1918;
          --cw-text-2: #3D3C38;
          --cw-text-3: #5E5D59;
          --cw-text-dim: #6E6C64;
          --cw-text-faint: #8A8880;
          --cw-surface: rgba(0,0,0,0.025);
          --cw-surface-2: rgba(0,0,0,0.04);
          --cw-border: rgba(0,0,0,0.08);
          --cw-track: rgba(0,0,0,0.04);
          --cw-hover: rgba(0,0,0,0.04);
          --cw-rail: rgba(0,0,0,0.08);
          --cw-scrollbar: rgba(0,0,0,0.22);
          background: var(--cw-bg);
          border-radius: 12px;
          overflow: hidden;
          font-family: var(--font-sans, -apple-system, BlinkMacSystemFont, sans-serif);
          color: var(--cw-text);
          border: 1px solid var(--cw-border);
        }
        .dark .cw-root {
          --cw-bg: #111110;
          --cw-text: #E8E6DC;
          --cw-text-2: #B8B6AE;
          --cw-text-3: #9C9A92;
          --cw-text-dim: #8A8880;
          --cw-text-faint: #6E6C64;
          --cw-surface: rgba(255,255,255,0.02);
          --cw-surface-2: rgba(255,255,255,0.015);
          --cw-border: rgba(255,255,255,0.06);
          --cw-track: rgba(255,255,255,0.03);
          --cw-hover: rgba(255,255,255,0.04);
          --cw-rail: rgba(255,255,255,0.04);
          --cw-scrollbar: rgba(255,255,255,0.18);
        }
        .cw-scroll::-webkit-scrollbar { width: 6px; }
        .cw-scroll::-webkit-scrollbar-track { background: transparent; }
        .cw-scroll::-webkit-scrollbar-thumb { background: var(--cw-scrollbar); border-radius: 3px; }
        @keyframes cw-blink { 50% { opacity: 0; } }
        @keyframes cw-fadein { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
        .cw-compacted-row { animation: cw-fadein 0.3s ease-out backwards; }
        .cw-mobile-fallback { display: none; padding: 14px 16px; border-radius: 8px; font-size: 14px; border: 1px solid rgba(0,0,0,0.1); background: rgba(0,0,0,0.03); }
        .dark .cw-mobile-fallback { border-color: rgba(255,255,255,0.15); background: rgba(255,255,255,0.04); }
        @media (max-width: 700px) {
          .cw-root { display: none !important; }
          .cw-mobile-fallback { display: block; }
        }
      `}</style>

      {}
      <div style={{
    padding: '16px 20px 12px',
    display: 'flex',
    alignItems: 'flex-end',
    gap: 24
  }}>
        <div style={{
    flex: 1,
    minWidth: 0
  }}>
          <div style={{
    fontSize: 18,
    fontWeight: 600,
    letterSpacing: -0.3,
    lineHeight: 1
  }}>
            Explore the context window
          </div>
          <div style={{
    fontSize: 14,
    color: 'var(--cw-text-dim)',
    marginTop: 4
  }}>
            A simulated session showing what enters context and what it costs
          </div>
        </div>
        <div style={{
    textAlign: 'right',
    flexShrink: 0
  }}>
          <div style={{
    fontFamily: mono,
    fontSize: 20,
    fontWeight: 600,
    color: barColor,
    letterSpacing: -0.5,
    lineHeight: 1
  }}>
            ~{fmt(totalTokens)}<span style={{
    fontSize: 15,
    fontWeight: 500,
    marginLeft: 4
  }}>tokens</span>
          </div>
          <div style={{
    fontFamily: mono,
    fontSize: 13,
    color: 'var(--cw-text-dim)',
    marginTop: 2
  }} title="Token counts are illustrative. Actual values vary with your CLAUDE.md size, MCP servers, and file lengths.">
            / {fmt(MAX)} · illustrative
          </div>
        </div>
      </div>

      {}
      <div style={{
    padding: '0 20px'
  }}>
        <div style={{
    height: 4,
    borderRadius: 2,
    background: 'var(--cw-track)',
    overflow: 'hidden',
    marginBottom: 6
  }}>
          <div style={{
    width: pct + '%',
    height: '100%',
    background: barColor,
    transition: 'width 0.6s cubic-bezier(0.4, 0, 0.2, 1), background 0.3s'
  }} />
        </div>
        <div style={{
    height: 28,
    borderRadius: 5,
    background: 'var(--cw-track)',
    border: '1px solid var(--cw-border)',
    overflow: 'hidden',
    display: 'flex'
  }}>
          {blocks.map((b, i) => {
    const w = Math.max(b.tokens / MAX * 100, 0.15);
    const isHov = b.visIdx === activeIdx;
    const catMatch = hovCat && b.color === hovCat;
    const dimmed = hovCat ? !catMatch : activeIdx !== null && !isHov;
    return <div key={b.id} onMouseEnter={() => setHovIdx(b.visIdx)} onMouseLeave={() => setHovIdx(null)} onClick={() => setSelIdx(selIdx === b.visIdx ? null : b.visIdx)} style={{
      width: w + '%',
      height: '100%',
      background: b.color,
      opacity: isHov || catMatch ? 1 : dimmed ? 0.25 : 0.65,
      borderRight: i < blocks.length - 1 ? '0.5px solid var(--cw-border)' : 'none',
      transition: 'opacity 0.15s',
      cursor: 'pointer'
    }} />;
  })}
        </div>
        <div style={{
    display: 'flex',
    gap: 12,
    marginTop: 6,
    flexWrap: 'wrap',
    justifyContent: 'space-between'
  }}>
          <div style={{
    display: 'flex',
    gap: 12,
    flexWrap: 'wrap'
  }}>
            {LEGEND.map(x => {
    const active = hovCat === x.c;
    return <div key={x.l} onMouseEnter={() => setHovCat(x.c)} onMouseLeave={() => setHovCat(null)} style={{
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      padding: '2px 6px',
      borderRadius: 4,
      cursor: 'pointer',
      background: active ? 'var(--cw-hover)' : 'transparent',
      transition: 'background 0.1s'
    }}>
                  <div style={{
      width: 6,
      height: 6,
      borderRadius: 1.5,
      background: x.c,
      opacity: active ? 1 : 0.7
    }} />
                  <span style={{
      fontSize: 12,
      color: active ? 'var(--cw-text)' : 'var(--cw-text-dim)'
    }}>{x.l}</span>
                </div>;
  })}
          </div>
          <div style={{
    display: 'flex',
    gap: 6,
    alignItems: 'center',
    fontSize: 12,
    color: 'var(--cw-text-dim)'
  }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#558A42" strokeWidth="2.5">
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
            </svg>
            <span>= appears in your terminal</span>
          </div>
        </div>
      </div>

      {}
      <div style={{
    display: 'flex',
    padding: '14px 20px 0',
    gap: 16,
    height: isFullscreen ? 'calc(100vh - 240px)' : 420
  }}>

        {}
        <div ref={scrollRef} className="cw-scroll" style={{
    flex: 1,
    minWidth: 0,
    overflowY: 'auto',
    paddingRight: 8,
    scrollBehavior: 'smooth'
  }}>
          {visible.length === 0 && !playing && <div style={{
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16
  }}>
              <div style={{
    fontFamily: mono,
    fontSize: 16,
    color: 'var(--cw-text-dim)',
    display: 'flex',
    alignItems: 'center',
    gap: 8
  }}>
                <span style={{
    color: 'var(--cw-text-faint)'
  }}>$</span>
                <span>claude</span>
                <span style={{
    display: 'inline-block',
    width: 8,
    height: 16,
    background: 'var(--cw-text-dim)',
    opacity: 0.5,
    animation: 'cw-blink 1s step-end infinite'
  }} />
              </div>
              <button onClick={() => setPlaying(true)} style={{
    padding: '10px 20px',
    borderRadius: 8,
    border: '1px solid rgba(217,119,87,0.3)',
    background: 'rgba(217,119,87,0.08)',
    color: '#D97757',
    fontSize: 15,
    fontWeight: 600,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: 8
  }}>
                <span>▶</span>
                <span>Start session</span>
              </button>
              <div style={{
    fontSize: 13,
    color: 'var(--cw-text-faint)',
    maxWidth: 280,
    textAlign: 'center',
    lineHeight: 1.5
  }}>
                Watch what loads into context, from the moment you run <code style={{
    fontFamily: mono
  }}>claude</code> through a full conversation.
              </div>
            </div>}
          {isCompacted && <div style={{
    marginBottom: 10,
    padding: '10px 12px',
    borderRadius: 6,
    background: 'rgba(217,119,87,0.05)',
    border: '1px solid rgba(217,119,87,0.15)'
  }}>
              <div style={{
    fontSize: 13,
    fontWeight: 600,
    color: '#D97757',
    marginBottom: 3
  }}>
                After /compact
              </div>
              <div style={{
    fontSize: 13,
    color: 'var(--cw-text-3)',
    lineHeight: 1.5,
    fontFamily: mono
  }}>
                {fmt(preCompactTotal)} → {fmt(totalTokens)} tokens · freed {fmt(preCompactTotal - totalTokens)}
              </div>
              <div style={{
    fontSize: 13,
    color: 'var(--cw-text-dim)',
    lineHeight: 1.5,
    marginTop: 4
  }}>
                This is what's left in context: startup content, which lives outside the message history and reloads after compaction, a structured summary of the entire conversation, the files modified most recently, and the body of each skill you invoked. Skill descriptions don't reload.
              </div>
            </div>}
          {time > 0 && visible.length > 0 && <div style={{
    fontSize: 12,
    fontWeight: 700,
    color: 'var(--cw-text-faint)',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
    marginBottom: 6,
    paddingLeft: 28
  }}>
              {isCompacted ? 'Reloaded after compact' : 'Before you type anything'}
            </div>}

          {time > 0 && visible.map((evt, i) => {
    const meta = KIND_META[evt.kind];
    const isHov = hovIdx === i;
    const prevKind = i > 0 ? visible[i - 1].kind : null;
    const isSub = evt.kind === 'sub';
    const enteringSubagent = isSub && prevKind !== 'sub';
    const leavingSubagent = prevKind === 'sub' && !isSub;
    let showPhase = null;
    if (isCompacted && evt.restoredAfterCompact) {
      if (prevKind === 'compact') showPhase = 'Restored after /compact';