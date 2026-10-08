[Part 2/3 of https://code.claude.com/docs/en/context-window.md, fetched 2026-10-08]

    } else if (evt.kind === 'user' && prevKind !== 'user') showPhase = 'You'; else if (evt.kind === 'claude' && prevKind === 'user') showPhase = 'Claude works'; else if (evt.label === 'Conversation summary') showPhase = 'Summarized by /compact';
    const isNewRow = isCompacted && !(evt.kind === 'auto' && evt.t < STARTUP_END);
    return <div key={evt.label + evt.t} className={isNewRow ? 'cw-compacted-row' : ''} style={isNewRow ? {
      animationDelay: `${i * 60}ms`
    } : {}}>
                {showPhase && <div style={{
      fontSize: 12,
      fontWeight: 700,
      color: 'var(--cw-text-faint)',
      textTransform: 'uppercase',
      letterSpacing: 0.6,
      marginTop: 14,
      marginBottom: 6,
      paddingLeft: 28
    }}>
                    {showPhase}
                  </div>}
                {enteringSubagent && <div style={{
      marginLeft: 28,
      marginTop: 6,
      marginBottom: 2,
      paddingLeft: 10,
      borderLeft: '2px solid rgba(155,123,196,0.4)',
      fontSize: 12,
      fontWeight: 600,
      color: '#9B7BC4',
      textTransform: 'uppercase',
      letterSpacing: 0.5
    }}>
                    Subagent's separate context window
                  </div>}
                {leavingSubagent && <div style={{
      marginLeft: 28,
      marginBottom: 6,
      paddingLeft: 10,
      paddingBottom: 6,
      borderLeft: '2px solid rgba(155,123,196,0.4)',
      fontSize: 12,
      color: 'var(--cw-text-dim)',
      fontFamily: mono
    }}>
                    ↓ {fmt(subTotal)} tokens stayed in subagent's context · only the summary returns
                  </div>}
                <div onMouseEnter={() => setHovIdx(i)} onMouseLeave={() => setHovIdx(null)} onClick={() => setSelIdx(selIdx === i ? null : i)} style={{
      display: 'flex',
      alignItems: 'flex-start',
      borderRadius: 6,
      cursor: 'pointer',
      background: selIdx === i || isHov ? 'var(--cw-hover)' : 'transparent',
      outline: selIdx === i ? '1px solid rgba(217,119,87,0.4)' : 'none',
      opacity: hovCat && evt.color !== hovCat ? 0.35 : 1,
      transition: 'background 0.1s, opacity 0.15s',
      marginLeft: isSub ? 28 : 0,
      paddingLeft: isSub ? 10 : 0,
      borderLeft: isSub ? '2px solid rgba(155,123,196,0.4)' : 'none'
    }}>
                  <div style={{
      width: 28,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      paddingTop: 8,
      flexShrink: 0
    }}>
                    <div style={{
      width: evt.kind === 'user' || evt.kind === 'compact' ? 10 : 7,
      height: evt.kind === 'user' || evt.kind === 'compact' ? 10 : 7,
      borderRadius: '50%',
      background: evt.color,
      opacity: isHov ? 1 : 0.6,
      transition: 'opacity 0.15s',
      boxShadow: isHov ? `0 0 8px ${evt.color}40` : 'none'
    }} />
                    {i < visible.length - 1 && <div style={{
      width: 1.5,
      flex: 1,
      background: 'var(--cw-rail)',
      marginTop: 2,
      minHeight: 6
    }} />}
                  </div>
                  <div style={{
      flex: 1,
      minWidth: 0,
      padding: '5px 10px 5px 4px',
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }}>
                    <span style={{
      fontSize: 12,
      fontWeight: 600,
      padding: '1px 5px',
      borderRadius: 3,
      background: meta.badgeBg,
      color: meta.badgeColor,
      flexShrink: 0,
      fontFamily: mono
    }}>
                      {meta.badge}
                    </span>
                    <span style={{
      fontSize: 15,
      fontFamily: mono,
      color: isHov ? 'var(--cw-text)' : evt.kind === 'user' ? '#558A42' : evt.kind === 'auto' ? 'var(--cw-text-dim)' : 'var(--cw-text-2)',
      flex: 1,
      minWidth: 0,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap',
      fontWeight: evt.kind === 'user' ? 550 : 400
    }}>
                      {evt.label}
                    </span>
                    {evt.tokens > 0 && <span style={{
      fontSize: 12,
      fontFamily: mono,
      color: 'var(--cw-text-faint)',
      flexShrink: 0
    }}>
                        +{fmt(evt.tokens)}
                      </span>}
                    {evt.subTokens > 0 && <span style={{
      fontSize: 12,
      fontFamily: mono,
      color: '#9B7BC4',
      flexShrink: 0,
      opacity: 0.6
    }}>
                        +{fmt(evt.subTokens)}
                      </span>}
                    {evt.tokens > 0 && <div style={{
      width: 50,
      height: 5,
      borderRadius: 2,
      background: 'var(--cw-track)',
      flexShrink: 0,
      overflow: 'hidden'
    }}>
                        <div style={{
      width: Math.min(evt.tokens / 5000 * 100, 100) + '%',
      height: '100%',
      background: evt.color,
      opacity: isHov ? 0.8 : 0.4,
      transition: 'opacity 0.15s'
    }} />
                      </div>}
                    <span style={{
      width: 14,
      flexShrink: 0,
      display: 'flex',
      justifyContent: 'center'
    }} title={VIS_META[evt.vis].label}>
                      {evt.vis !== 'hidden' && <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={evt.vis === 'full' ? '#558A42' : 'currentColor'} style={{
      color: 'var(--cw-text-faint)',
      opacity: evt.vis === 'full' ? 1 : 0.5
    }} strokeWidth="2">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
                        </svg>}
                    </span>
                  </div>
                </div>
              </div>;
  })}

          {activeGate && (activeGate.kind === 'prompt' || activeGate.kind === 'bang' || activeGate.kind === 'slash') && <div style={{
    paddingLeft: 28,
    marginTop: 12,
    paddingRight: 8
  }}>
              <div style={{
    fontSize: 11,
    fontWeight: 600,
    color: '#6BA656',
    fontFamily: mono,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 4,
    paddingLeft: 2
  }}>
                You type in your terminal
              </div>
              <div style={{
    display: 'flex',
    alignItems: 'flex-start',
    gap: 8,
    padding: '10px 12px',
    borderRadius: 6,
    background: 'rgba(85,138,66,0.06)',
    border: '1px solid rgba(85,138,66,0.2)'
  }}>
                <span style={{
    color: '#558A42',
    fontSize: 15,
    fontFamily: mono,
    flexShrink: 0
  }}>❯</span>
                <span style={{
    fontSize: 15,
    fontFamily: mono,
    color: 'var(--cw-text-2)',
    flex: 1,
    lineHeight: 1.5
  }}>
                  {activeGate.text}
                  <span style={{
    display: 'inline-block',
    width: 7,
    height: 13,
    marginLeft: 2,
    background: '#558A42',
    opacity: 0.5,
    verticalAlign: 'middle',
    animation: 'cw-blink 1s step-end infinite'
  }} />
                </span>
                <button onClick={sendPrompt} style={{
    padding: '5px 12px',
    borderRadius: 5,
    border: 'none',
    background: '#558A42',
    color: '#fff',
    fontSize: 13,
    fontWeight: 600,
    cursor: 'pointer',
    flexShrink: 0
  }}>
                  {activeGate.kind === 'prompt' ? 'Send ↵' : 'Run ↵'}
                </button>
              </div>
            </div>}
          {activeGate && activeGate.kind === 'compact' && <div style={{
    paddingLeft: 28,
    marginTop: 12,
    paddingRight: 8
  }}>
              <div style={{
    padding: '12px 14px',
    borderRadius: 6,
    background: 'rgba(217,119,87,0.06)',
    border: '1px solid rgba(217,119,87,0.25)'
  }}>
                <div style={{
    fontSize: 13,
    color: 'var(--cw-text-3)',
    marginBottom: 8,
    lineHeight: 1.5
  }}>
                  Context is at <span style={{
    fontFamily: mono,
    fontWeight: 600,
    color: barColor
  }}>{fmt(totalTokens)} tokens</span>.
                  Run <code style={{
    fontFamily: mono,
    background: 'var(--cw-track)',
    padding: '1px 4px',
    borderRadius: 3
  }}>/compact</code> to
                  summarize older exchanges and free space for more work.
                </div>
                <div style={{
    display: 'flex',
    alignItems: 'center',
    gap: 8
  }}>
                  <span style={{
    color: '#D97757',
    fontSize: 15,
    fontFamily: mono
  }}>❯</span>
                  <span style={{
    fontSize: 15,
    fontFamily: mono,
    color: 'var(--cw-text-2)',
    flex: 1
  }}>
                    {activeGate.text}
                  </span>
                  <button onClick={sendPrompt} style={{
    padding: '5px 12px',
    borderRadius: 5,
    border: 'none',
    background: '#D97757',
    color: '#fff',
    fontSize: 13,
    fontWeight: 600,
    cursor: 'pointer',
    flexShrink: 0
  }}>
                    Run ↵
                  </button>
                </div>
              </div>
            </div>}
        </div>

        {}
        <div style={{
    width: 300,
    flexShrink: 0,
    display: 'flex',
    flexDirection: 'column'
  }}>
          <div ref={detailRef} className="cw-scroll" style={{
    padding: '14px 16px',
    borderRadius: 10,
    background: 'var(--cw-surface)',
    border: '1px solid var(--cw-border)',
    flex: 1,
    minHeight: 0,
    overflowY: 'auto',
    display: 'flex',
    flexDirection: 'column',
    gap: 10
  }}>
            {hovEvent ? <div>
                <div style={{
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8
  }}>
                  <div style={{
    width: 10,
    height: 10,
    borderRadius: 3,
    background: hovEvent.color,
    opacity: 0.8
  }} />
                  <span style={{
    fontSize: 16,
    fontWeight: 600
  }}>{hovEvent.label}</span>
                </div>
                <div style={{
    display: 'flex',
    width: 'fit-content',
    padding: '3px 8px',
    borderRadius: 4,
    marginBottom: 8,
    background: KIND_META[hovEvent.kind].badgeBg
  }}>
                  <span style={{
    fontSize: 12,
    fontWeight: 600,
    color: KIND_META[hovEvent.kind].badgeColor
  }}>
                    {KIND_META[hovEvent.kind].detail}
                  </span>
                </div>
                {hovEvent.tokens > 0 && <div style={{
    fontSize: 14,
    fontFamily: mono,
    color: 'var(--cw-text-dim)',
    marginBottom: 6
  }}>
                    {fmt(hovEvent.tokens)} tokens
                  </div>}
                {hovEvent.subTokens > 0 && <div style={{
    fontSize: 14,
    fontFamily: mono,
    color: '#9B7BC4',
    marginBottom: 6
  }}>
                    {fmt(hovEvent.subTokens)} tokens in the subagent's context
                  </div>}
                <p style={{
    fontSize: 15,
    color: 'var(--cw-text-3)',
    lineHeight: 1.55,
    margin: 0
  }}>
                  {renderWithCode(hovEvent.desc)}
                </p>
                <div style={{
    marginTop: 10,
    padding: '8px 10px',
    borderRadius: 6,
    background: hovEvent.vis === 'full' ? 'rgba(85,138,66,0.08)' : 'var(--cw-surface-2)',
    border: '1px solid ' + (hovEvent.vis === 'full' ? 'rgba(85,138,66,0.2)' : 'var(--cw-border)')
  }}>
                  <div style={{
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    marginBottom: 3
  }}>
                    <span style={{
    fontSize: 13,
    color: hovEvent.vis === 'full' ? '#558A42' : 'var(--cw-text-dim)'
  }}>
                      {hovEvent.vis === 'full' ? '●' : hovEvent.vis === 'brief' ? '◐' : '○'}
                    </span>
                    <span style={{
    fontSize: 12,
    fontWeight: 600,
    color: 'var(--cw-text-2)'
  }}>
                      {VIS_META[hovEvent.vis].label}
                    </span>
                  </div>
                  <div style={{
    fontSize: 13,
    color: 'var(--cw-text-dim)',
    lineHeight: 1.4
  }}>
                    {VIS_META[hovEvent.vis].sub}
                  </div>
                </div>
                {hovEvent.tip && <div style={{
    marginTop: 10,
    padding: '8px 10px',
    borderRadius: 6,
    background: 'rgba(85,138,66,0.06)',
    border: '1px solid rgba(85,138,66,0.15)'
  }}>
                    <div style={{
    fontSize: 12,
    fontWeight: 600,
    color: '#558A42',
    marginBottom: 3,
    display: 'flex',
    alignItems: 'center',
    gap: 4
  }}>
                      <span>💡</span> Save context
                    </div>
                    <div style={{
    fontSize: 13,
    color: 'var(--cw-text-3)',
    lineHeight: 1.5
  }}>
                      {renderWithCode(hovEvent.tip)}
                    </div>
                  </div>}
                {hovEvent.link && <a href={hovEvent.link} style={{
    display: 'inline-block',
    marginTop: 10,
    fontSize: 13,
    color: '#D97757',
    textDecoration: 'none',
    borderBottom: '1px solid rgba(217,119,87,0.3)'
  }}>
                    Learn more →
                  </a>}
              </div> : <div style={{
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    textAlign: 'center',
    gap: 4,
    padding: '12px 0 4px'
  }}>
                <div style={{
    fontSize: 22,
    opacity: 0.2
  }}>👁</div>
                <div style={{
    fontSize: 14,
    fontWeight: 500,
    color: 'var(--cw-text-dim)'
  }}>Hover or click any event</div>
                <div style={{
    fontSize: 12,
    color: 'var(--cw-text-faint)',
    lineHeight: 1.4,
    maxWidth: 200
  }}>
                  Hover to preview. Click to pin so you can scroll.
                </div>
              </div>}

            <div style={{
    padding: '10px 12px',
    borderRadius: 8,
    background: 'rgba(217,119,87,0.05)',
    border: '1px solid rgba(217,119,87,0.12)'
  }}>
              <div style={{
    fontSize: 11,
    fontWeight: 700,
    color: '#D97757',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 3
  }}>
                Key takeaway
              </div>
              <div style={{
    fontSize: 13,
    color: 'var(--cw-text-3)',
    lineHeight: 1.5
  }}>
                {takeaway}
              </div>
            </div>

            <div style={{
    padding: '10px 12px',
    borderRadius: 8,
    background: 'var(--cw-surface-2)',
    border: '1px solid var(--cw-border)'
  }}>
              <div style={{
    fontSize: 11,
    fontWeight: 700,
    color: 'var(--cw-text-dim)',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 3
  }}>
                In your terminal you see
              </div>
              <div style={{
    fontSize: 13,
    color: 'var(--cw-text-3)',
    lineHeight: 1.5
  }}>
                {terminalView}
              </div>
            </div>
          </div>
        </div>
      </div>

      {}
      <div style={{
    padding: '10px 20px 14px',
    display: 'flex',
    alignItems: 'center',
    gap: 10
  }}>
        <button aria-label={time >= 1 ? 'Restart' : activeGate ? 'Continue' : playing ? 'Pause' : 'Play'} onClick={() => {
    if (time >= 1) {
      setTime(0);
      setGatesPassed(0);
      setSelIdx(null);
      setHovIdx(null);
      setPlaying(true);
    } else if (activeGate) sendPrompt(); else setPlaying(!playing);
  }} style={{
    width: 30,
    height: 30,
    borderRadius: 6,
    border: 'none',
    background: 'rgba(217,119,87,0.1)',
    color: '#D97757',
    cursor: 'pointer',
    fontSize: 15,
    fontWeight: 700,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center'
  }}>
          {time >= 1 ? '↺' : playing ? '⏸' : '▶'}
        </button>
        <div style={{
    flex: 1,
    height: 3,
    borderRadius: 2,
    background: 'var(--cw-track)',
    overflow: 'hidden'
  }}>
          <div style={{
    width: time * 100 + '%',
    height: '100%',
    background: '#D97757',
    transition: 'width 0.1s linear'
  }} />
        </div>
        <span style={{
    fontSize: 12,
    fontFamily: mono,
    color: 'var(--cw-text-faint)',
    minWidth: 30
  }}>
          {Math.round(time * 100)}%
        </span>
        <button onClick={toggleFullscreen} aria-label={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'} title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'} style={{
    width: 28,
    height: 28,
    borderRadius: 6,
    border: '1px solid var(--cw-border)',
    background: 'var(--cw-surface)',
    color: 'var(--cw-text-dim)',
    cursor: 'pointer',
    fontSize: 15,
    flexShrink: 0,
    marginLeft: 4,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center'
  }}>
          {isFullscreen ? '⤡' : '⛶'}
        </button>
      </div>
    </div>
    </>;
};

Claude Code's context window holds everything Claude knows about your session: your instructions, the files it reads, its own responses, and content that never appears in your terminal. The timeline below plays a full session from startup to compaction: what loads before you type, what each file read, rule, and hook adds as Claude works, and how a subagent keeps large reads out of your context. See [the written breakdown](#what-the-timeline-shows) for the same content as a list.

<ContextWindow />

## What the timeline shows

The session walks through a realistic flow with representative token counts:

* **Before you type anything**: CLAUDE.md, auto memory, MCP tool names, and skill descriptions all load into context. [AGENTS.md files](/docs/en/memory#agents-md) can load in place of CLAUDE.md. Your own setup may add more here, like an [output style](/docs/en/output-styles) or text from [`--append-system-prompt`](/docs/en/cli-reference).
* **As Claude works**: each file read adds to context, [path-scoped rules](/docs/en/memory#path-specific-rules) load automatically alongside matching files, and a [PostToolUse hook](/docs/en/hooks-guide) fires after each edit.
* **The follow-up prompt**: a [subagent](/docs/en/sub-agents) handles the research in its own separate context window, so the large file reads stay out of yours. Only the summary and a small metadata trailer come back.
* **At the end of the walkthrough**: you run `/compact`, which replaces the conversation with a structured summary. Most startup content reloads automatically; the table below shows what happens to each mechanism.

## What survives compaction

When a long session compacts, Claude Code summarizes the conversation history to fit the context window. As of v2.1.198, the summarization request inherits your session's [extended thinking](/docs/en/model-config#extended-thinking) configuration, so it reasons with thinking enabled when your session has it enabled and stays off otherwise. Thinking affects only how the summary is produced; your session settings are unchanged afterward. What happens to each kind of content depends on how it was loaded:

| Mechanism | After compaction |
| :- | :- |
| System prompt and output style | Both still apply |
| Project-root CLAUDE.md and unscoped rules | Re-injected from disk |
| Auto memory | Re-injected from disk |
| [Git status snapshot](/docs/en/settings-reference#includegitinstructions) | Claude Code reads a fresh one from your repository |
| The plan Claude wrote in [plan mode](/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) | Re-injected from disk |
| Rules with `paths:` frontmatter | Claude Code reloads them [on demand](/docs/en/memory#path-specific-rules) |
| Nested CLAUDE.md in subdirectories | Claude Code reloads them [on demand](/docs/en/memory#how-claude-md-files-load) |
| Files Claude read or edited | Claude Code re-reads up to five, most recently modified first |
| Invoked skill bodies | Re-injected, capped at 5,000 tokens per skill and 25,000 tokens total; oldest dropped first |
| [Background commands](/docs/en/interactive-mode#background-bash-commands) and background [subagents](/docs/en/sub-agents#run-subagents-in-foreground-or-background) | Keep running. Claude Code reminds Claude which ones are still running so it doesn't start a duplicate |
| Context that hooks added earlier | Summarized with the rest of the conversation |
| [SessionStart hooks](/docs/en/hooks-guide#re-inject-context-after-compaction) that match the `compact` source | Claude Code runs them and adds their output to the compacted context |

Right after compaction, Claude Code re-reads up to five of the files Claude has read or edited in the session, choosing the ones modified most recently. A file over 5,000 tokens comes back as a path reference without its content, shown as `Referenced file` instead of `Read`.

Path-scoped rules and nested CLAUDE.md files load into message history when Claude reads, writes, or edits their trigger file, so compaction summarizes them away with everything else. If a rule must persist across compaction, drop the `paths:` frontmatter or move it to the project-root CLAUDE.md.

Skill bodies are re-injected after compaction, but large skills are truncated to fit the per-skill cap, and the oldest invoked skills are dropped once the total budget is exceeded. Truncation keeps the start of the file, so put the most important instructions near the top of `SKILL.md`.

## When your context fills up

Claude Code compacts automatically as you approach the limit, so a full context window doesn't end your session. The automatic pass works the same way as the `/compact` step in the timeline. See [When context fills up](/docs/en/how-claude-code-works#when-context-fills-up) for what it preserves.

You can also act before the automatic pass runs:

* **Compact with a focus**: run `/compact` with instructions, like `/compact focus on the auth bug fix`, before starting a long new task. The summary keeps what you choose instead of what the automatic pass guesses is important.
* **Compact part of the conversation**: run `/rewind`, select a message, and choose **Summarize from here** or **Summarize up to here**. See [Rewind and summarize](/docs/en/checkpointing#rewind-and-summarize) for what each option keeps and how to guide the summary.
* **Compact earlier**: run [`/autocompact`](/docs/en/commands#all-commands) with a token count, like `/autocompact 500k`, to set how full the context window gets before the automatic pass runs. See [Set the auto-compact window](/docs/en/model-config#set-the-auto-compact-window) for accepted values and overrides.
* **Clear between tasks**: run `/clear` when switching to unrelated work. Old conversation crowds out the files you need next and costs tokens on every message.
* **Delegate large reads**: send research to a [subagent](/docs/en/sub-agents) so the file contents stay in its context window, not yours.

If you need a larger window rather than a smaller conversation, Fable models, Sonnet 5 and later, Haiku 5.5, Opus 4.6 and later, and Sonnet 4.6 support a 1 million token context window. See [Extended context](/docs/en/model-config#extended-context) for availability by plan and how to select a `[1m]` model variant. Compaction works the same way at the larger limit.

Sonnet 5.5 and Sonnet 5 run with the 1M context window and have no `[1m]` variant to select. See [Sonnet 5.5 and Sonnet 5 context window](/docs/en/model-config#sonnet-5-5-and-sonnet-5-context-window) for their auto-compaction thresholds, and [the context window behind a gateway](/docs/en/model-config#context-window-behind-a-gateway) for how Claude Code sizes the window when you set `ANTHROPIC_BASE_URL` to an [LLM gateway](/docs/en/llm-gateway).

The point where automatic compaction runs depends on your model and configuration. See [Default auto-compact thresholds](/docs/en/model-config#default-auto-compact-thresholds) for the boundaries per model, and [Correct the window for a gateway or custom model ID](/docs/en/model-config#correct-the-window-for-a-gateway-or-custom-model-id) if Claude Code assumes the wrong window for your model ID, such as an [LLM gateway](/docs/en/llm-gateway) alias.
