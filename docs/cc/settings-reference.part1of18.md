[Part 1/18 of https://code.claude.com/docs/en/settings-reference.md, fetched 2026-10-08]

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# All settings

> Complete reference for every Claude Code settings.json key: where each one goes, its type and default, and a paste-ready example, with an index of every key.

export const BackToIndex = ({href = '#all-settings', label = 'Back to index'}) => {
  const [show, setShow] = useState(false);
  useEffect(() => {
    const onScroll = () => setShow(window.scrollY > window.innerHeight);
    onScroll();
    window.addEventListener('scroll', onScroll, {
      passive: true
    });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);
  return <div className="not-prose">
      <style>{`
        .bti-btn {
          position: fixed; right: 20px; bottom: 20px; z-index: 40;
          display: inline-flex; align-items: center; gap: 6px;
          padding: 8px 12px; border-radius: 999px;
          font-size: 13px; font-weight: 500; line-height: 1; text-decoration: none;
          color: #1f1f1f; background: #ffffff; border: 1px solid #d9d9d9;
          box-shadow: 0 2px 8px rgba(0,0,0,0.12);
          opacity: 0; pointer-events: none; transform: translateY(6px);
          transition: opacity 160ms ease, transform 160ms ease;
        }
        .bti-btn.bti-show { opacity: 1; pointer-events: auto; transform: translateY(0); }
        .bti-btn:hover { border-color: #b3b3b3; }
        .dark .bti-btn { color: #ececec; background: #1e1e1e; border-color: #3a3a3a; box-shadow: 0 2px 8px rgba(0,0,0,0.5); }
        .dark .bti-btn:hover { border-color: #5a5a5a; }
        @media (max-width: 1279px) { .bti-btn { bottom: 112px; } }
        @media print { .bti-btn { display: none; } }
      `}</style>
      <a className={'bti-btn' + (show ? ' bti-show' : '')} href={href} aria-hidden={!show} tabIndex={show ? 0 : -1}>
        <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M8 13V3M3.5 7.5 8 3l4.5 4.5" /></svg>
        {label}
      </a>
    </div>;
};

export const ReferenceFilter = ({placeholder, noun, facets, facetOrder, columnHelp, children}) => {
  const useLive = init => {
    const [v, setV] = useState(init);
    const ref = useRef(init);
    return [v, ref, x => {
      ref.current = x;
      setV(x);
    }];
  };
  const cap = s => s.charAt(0).toUpperCase() + s.slice(1);
  const plural = s => s.endsWith('y') ? s.slice(0, -1) + 'ies' : s + 's';
  const facetNames = facets || ['category', 'topic', 'scope', 'where'];
  const orderOf = {};
  Object.keys(facetOrder || ({})).forEach(k => {
    orderOf[k] = facetOrder[k].map(x => String(x).toLowerCase());
  });
  const rankIn = (col, v) => {
    const list = orderOf[col];
    if (!list) return -1;
    const i = list.indexOf(String(v).toLowerCase());
    return i < 0 ? list.length : i;
  };
  const cmpValues = col => (a, b) => {
    const ra = rankIn(col, a);
    const rb = rankIn(col, b);
    if (ra !== rb) return ra - rb;
    return a < b ? -1 : a > b ? 1 : 0;
  };
  const help = columnHelp || ({});
  const FIRST_COL_HELP = 'Click an entry to open it.';
  const optionLabel = (f, c) => c === 'All' ? 'All ' + plural(f.label.toLowerCase()) : c;
  const nounText = noun || 'entries';
  const placeholderText = placeholder || 'Filter this reference';
  const rootRef = useRef(null);
  const tablesRef = useRef(null);
  const searchRef = useRef(null);
  const menuRef = useRef({});
  const [q, qRef, setQ] = useLive('');
  const [sel, selRef, setSel] = useLive({});
  const [sortBy, sortRef, setSortBy] = useLive(null);
  const [menuOpen, menuOpenRef, setMenu] = useLive(null);
  const [facetList, setFacetList] = useState([]);
  const [firstHead, setFirstHead] = useState('');
  const [counts, setCounts] = useState({
    shown: 0,
    total: 0
  });
  const [disabled, setDisabled] = useState(false);
  const menuBtn = name => menuRef.current[name] ? menuRef.current[name].querySelector(':scope > button') : null;
  const menuList = name => menuRef.current[name] ? menuRef.current[name].querySelector('[role="listbox"]') : null;
  const closeMenu = name => {
    setMenu(null);
    const btn = menuBtn(name);
    if (btn) btn.focus();
  };
  const focusSelected = name => {
    const list = menuList(name);
    if (!list) return;
    const btn = list.querySelector('button[aria-selected="true"]') || list.querySelector('button');
    if (btn) btn.focus();
  };
  const setFacet = (name, value) => {
    setSel(Object.assign({}, selRef.current, {
      [name]: value
    }));
    apply(qRef.current);
    closeMenu(name);
  };
  const sortTables = by => {
    (tablesRef.current || []).forEach(tab => {
      const t = tab.el;
      const idx = tab.heads.indexOf(by);
      const body = t.querySelector('tbody');
      if (idx < 0 || !body) return;
      const rows = [...body.querySelectorAll('tr')];
      const keyOf = r => r.children[idx] ? r.children[idx].textContent.trim().toLowerCase() : '';
      const cmp = cmpValues(by);
      rows.map((r, i) => ({
        r,
        i: Number(r.dataset.sfIndex !== undefined ? r.dataset.sfIndex : i),
        k: keyOf(r)
      })).sort((a, b) => cmp(a.k, b.k) || a.i - b.i).forEach(x => body.appendChild(x.r));
      [...t.querySelectorAll('thead th')].forEach((h, i) => {
        const sortable = tab.heads[i] === tab.heads[0] || facetNames.indexOf(tab.heads[i]) > -1;
        if (sortable) h.setAttribute('aria-sort', i === idx ? 'ascending' : 'none'); else h.removeAttribute('aria-sort');
      });
    });
  };
  const scan = () => {
    const tables = [];
    let el = rootRef.current ? rootRef.current.nextElementSibling : null;
    while (el) {
      if (el.tagName === 'H2' || el.querySelector(':scope > h2')) break;
      const found = el.tagName === 'TABLE' ? [el] : [...el.querySelectorAll('table')];
      found.forEach(t => {
        const headCells = [...t.querySelectorAll('thead th, thead td')];
        const heads = headCells.map(h => h.textContent.trim().toLowerCase());
        if (heads.length === 0) return;
        const facetIdx = {};
        heads.forEach((h, i) => {
          if (facetNames.indexOf(h) > -1) facetIdx[h] = i;
        });
        if (!t.dataset.sfDecorated) {
          t.dataset.sfDecorated = '1';
          headCells.forEach((h, i) => {
            const text = i === 0 ? help[heads[0]] || FIRST_COL_HELP : help[heads[i]];
            if (text) h.title = text;
          });
        }
        const rows = [...t.querySelectorAll('tbody tr')].map((r, i) => {
          if (r.dataset.sfIndex === undefined) r.dataset.sfIndex = String(i);
          const cells = r.querySelectorAll('td');
          const fv = {};
          Object.keys(facetIdx).forEach(h => {
            fv[h] = cells[facetIdx[h]] ? cells[facetIdx[h]].textContent.trim() : '';
          });
          return {
            el: r,
            text: [...cells].map(c => c.textContent).join(' ').toLowerCase(),
            facets: fv,
            anchors: [...r.querySelectorAll('a[href^="#"]')].map(a => a.getAttribute('href').slice(1)),
            ids: [...r.querySelectorAll('[id]')].map(n => n.id)
          };
        });
        tables.push({
          el: t,
          box: t.closest('[data-table-wrapper]') || t,
          rows,
          heads
        });
      });
      el = el.nextElementSibling;
    }
    tablesRef.current = tables;
    if (sortRef.current) sortTables(sortRef.current);
    return tables;
  };
  const apply = query => {
    let tables = tablesRef.current || scan();
    if (tables.some(t => !t.el.isConnected)) tables = scan();
    const needle = query.trim().toLowerCase();
    const sel = selRef.current;
    const activeFacets = Object.keys(sel).filter(h => sel[h] && sel[h] !== 'All');
    const show = (el, on) => {
      const want = on ? '' : 'none';
      if (el.style.display !== want) el.style.display = want;
    };
    let total = 0;
    let shown = 0;
    const visibleTargets = new Set();
    tables.forEach(t => {
      let tableVisible = 0;
      t.rows.forEach(row => {
        total += 1;
        const catOk = activeFacets.every(h => {
          const v = row.facets[h];
          return v === sel[h] || v === '' || v === undefined;
        });
        const match = catOk && (needle === '' || row.text.includes(needle));
        show(row.el, match);
        if (match) {
          tableVisible += 1;
          row.anchors.forEach(a => visibleTargets.add(a));
        }
      });
      show(t.box, !(t.rows.length > 0 && tableVisible === 0));
      shown += tableVisible;
    });
    if (shown < total && visibleTargets.size > 0) {
      tables.forEach(t => {
        t.rows.forEach(row => {
          if (row.el.style.display === 'none' && row.ids.some(id => visibleTargets.has(id))) {
            show(row.el, true);
            show(t.box, true);
            shown += 1;
          }
        });
      });
    }
    setCounts({
      shown,
      total
    });
    return total;
  };
  const deriveFacets = tables => {
    const seen = {};
    tables.forEach(t => t.rows.forEach(r => {
      Object.keys(r.facets).forEach(h => {
        if (!seen[h]) seen[h] = [];
        if (r.facets[h] && seen[h].indexOf(r.facets[h]) === -1) seen[h].push(r.facets[h]);
      });
    }));
    const list = facetNames.filter(h => seen[h] && seen[h].length > 0).map(h => ({
      name: h,
      label: cap(h),
      values: seen[h].sort(cmpValues(h))
    }));
    setFacetList(list);
    const first = tables[0] ? tables[0].heads[0] : '';
    setFirstHead(first);
    if (!sortRef.current && first) {
      setSortBy(first);
      sortTables(first);
    }
    const init = {};
    list.forEach(f => {
      init[f.name] = selRef.current[f.name] || 'All';
    });
    setSel(init);
  };
  const onChange = value => {
    setQ(value);
    apply(value);
  };
  const clearAll = () => {
    const next = {};
    Object.keys(selRef.current).forEach(k => {
      next[k] = 'All';
    });
    setSel(next);
    setQ('');
    apply('');
    if (searchRef.current) searchRef.current.focus();
  };
  useEffect(() => {
    const tables = scan();
    deriveFacets(tables);
    const total = apply('');
    let retryTimer;
    if (total === 0) {
      retryTimer = setTimeout(() => {
        tablesRef.current = null;
        if (apply(qRef.current) > 0) deriveFacets(tablesRef.current); else setDisabled(true);
      }, 500);
    }
    const onKey = e => {
      if (e.key === 'Escape' && menuOpenRef.current !== null) closeMenu(menuOpenRef.current);
      if (!searchRef.current) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const active = document.activeElement;
      const tag = active && active.tagName;
      const editable = active && active.isContentEditable;
      const interactive = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'BUTTON' || tag === 'A' || editable || active && active.getAttribute && active.getAttribute('role');
      if (e.key === '/' && !interactive) {
        const r = rootRef.current ? rootRef.current.getBoundingClientRect() : null;
        if (r && r.bottom > 0 && r.top < (window.innerHeight || 0)) {
          e.preventDefault();
          setMenu(null);
          searchRef.current.focus();
        }
      }
      if (e.key === 'Escape' && menuOpenRef.current === null && active === searchRef.current) {
        onChange('');
        searchRef.current.blur();
      }
    };
    const onDocClick = e => {
      const open = menuOpenRef.current;
      if (open !== null && menuRef.current[open] && !menuRef.current[open].contains(e.target)) setMenu(null);
    };
    window.addEventListener('keydown', onKey);
    document.addEventListener('mousedown', onDocClick);
    return () => {
      if (retryTimer) clearTimeout(retryTimer);
      window.removeEventListener('keydown', onKey);
      document.removeEventListener('mousedown', onDocClick);
      (tablesRef.current || []).forEach(t => {
        t.box.style.display = '';
        t.rows.forEach(row => {
          row.el.style.display = '';
        });
      });
    };
  }, []);
  useEffect(() => {
    if (menuOpen !== null) focusSelected(menuOpen);
  }, [menuOpen]);
  if (disabled) return null;
  const facetActive = Object.keys(sel).some(h => sel[h] && sel[h] !== 'All');
  const sortOptions = [firstHead].concat(facetList.map(f => f.name)).filter((h, i, a) => h && a.indexOf(h) === i);
  return <>
      <style>{`
        .sf-root {
          --sf-accent: #D97757;
          --sf-bg: #fff;
          --sf-border: #E8E6DC;
          --sf-text: #141413;
          --sf-text-3: #73726C;
          --sf-text-4: #9C9A92;
        }
        .dark .sf-root {
          --sf-bg: #1a1918;
          --sf-border: #3a3936;
          --sf-text: #e8e6dc;
          --sf-text-3: #9c9a92;
          --sf-text-4: #73726c;
        }
        .sf-root .sf-end {
          position: absolute;
          right: 10px;
          top: 50%;
          transform: translateY(-50%);
        }
        .sf-root .sf-x {
          background: none;
          border: none;
          cursor: pointer;
          color: var(--sf-text-3);
          font-size: 14px;
          padding: 2px 4px;
          line-height: 1;
        }
      `}</style>
      <div ref={rootRef} className="sf-root" style={{
    margin: '16px 0 8px'
  }}>
        <div style={{
    display: 'flex',
    gap: '8px',
    flexWrap: 'wrap',
    alignItems: 'center'
  }}>
        <div style={{
    position: 'relative',
    flex: '1 1 260px',
    maxWidth: '480px'
  }}>
          <input ref={searchRef} value={q} onChange={e => onChange(e.target.value)} placeholder={placeholderText} aria-label={placeholderText} style={{
    width: '100%',
    padding: '8px 56px 8px 12px',
    borderRadius: '8px',
    border: '1px solid var(--sf-border)',
    background: 'var(--sf-bg)',
    color: 'var(--sf-text)',
    fontSize: '14px',
    outline: 'none',
    boxSizing: 'border-box'
  }} />
          {q ? <button type="button" onClick={() => {
    onChange('');
    if (searchRef.current) searchRef.current.focus();
  }} aria-label="Clear text" className="sf-end sf-x">
              ×
            </button> : <span className="sf-end" style={{
    fontFamily: 'var(--font-mono, ui-monospace, monospace)',
    fontSize: '11px',
    color: 'var(--sf-text-4)',
    border: '1px solid var(--sf-border)',
    borderRadius: '3px',
    padding: '0 5px',
    pointerEvents: 'none'
  }}>
              /
            </span>}
        </div>
        {facetList.map(f => {
    const cur = sel[f.name] || 'All';
    const isOpen = menuOpen === f.name;
    return <div key={f.name} ref={el => {
      menuRef.current[f.name] = el;
    }} style={{
      position: 'relative'
    }}>
            <button type="button" onClick={() => setMenu(isOpen ? null : f.name)} onKeyDown={e => {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (!isOpen) setMenu(f.name); else focusSelected(f.name);
      }
    }} aria-haspopup="listbox" aria-expanded={isOpen} style={{
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      padding: cur !== 'All' ? '8px 30px 8px 12px' : '8px 12px',
      borderRadius: '8px',
      border: '1px solid ' + (cur !== 'All' ? 'var(--sf-accent)' : 'var(--sf-border)'),
      background: 'var(--sf-bg)',
      color: cur === 'All' ? 'var(--sf-text-3)' : 'var(--sf-text)',
      fontSize: '13.5px',
      cursor: 'pointer',
      whiteSpace: 'nowrap',
      maxWidth: '260px'
    }}>
              <span style={{
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }}>
                {f.label + ': ' + optionLabel(f, cur)}
              </span>
              <span aria-hidden="true" style={{
      fontSize: '9px',
      color: 'var(--sf-text-4)',
      transform: isOpen ? 'rotate(180deg)' : 'none',
      transition: 'transform 120ms'
    }}>
                ▼
              </span>
            </button>
            {cur !== 'All' && <button type="button" onClick={() => setFacet(f.name, 'All')} aria-label={'Clear ' + f.label + ' filter'} title={'Clear ' + f.label + ' filter'} className="sf-end sf-x">
                ×
              </button>}
            {isOpen && <div role="listbox" aria-label={f.label} onKeyDown={e => {
      const items = [...e.currentTarget.querySelectorAll('button')];
      const idx = items.indexOf(document.activeElement);
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        (items[idx + 1] || items[0]).focus();
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        (items[idx - 1] || items[items.length - 1]).focus();
      } else if (e.key === 'Home') {
        e.preventDefault();
        if (items[0]) items[0].focus();
      } else if (e.key === 'End') {
        e.preventDefault();
        if (items[items.length - 1]) items[items.length - 1].focus();
      } else if (e.key === 'Tab') {
        closeMenu(f.name);
      }
    }} style={{
      position: 'absolute',
      top: 'calc(100% + 6px)',
      left: 0,
      zIndex: 1000,
      minWidth: '260px',
      maxHeight: '340px',
      overflowY: 'auto',
      background: 'var(--sf-bg)',
      border: '1px solid var(--sf-border)',
      borderRadius: '10px',
      boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
      padding: '5px'
    }}>
                {['All'].concat(f.values).map(c => {
      const selected = cur === c;
      return <button key={c} role="option" aria-selected={selected} tabIndex={-1} onClick={() => setFacet(f.name, c)} style={{
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        width: '100%',
        textAlign: 'left',
        padding: '7px 10px',
        borderRadius: '6px',
        border: 'none',
        background: 'transparent',
        color: selected ? 'var(--sf-accent)' : 'var(--sf-text)',
        fontWeight: selected ? 600 : 400,
        fontSize: '13.5px',
        cursor: 'pointer'
      }}>
                      <span aria-hidden="true" style={{
        width: '14px',
        color: 'var(--sf-accent)',
        flexShrink: 0
      }}>
                        {selected ? '✓' : ''}
                      </span>
                      {optionLabel(f, c)}
                    </button>;
    })}
              </div>}
          </div>;
  })}
        {sortOptions.length > 1 && <div role="group" aria-label="Sort by" style={{
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
    fontSize: '13px',
    color: 'var(--sf-text-3)',
    whiteSpace: 'nowrap'
  }}>
            <span style={{
    marginRight: '4px'
  }}>Sort by</span>
            {sortOptions.map(o => {
    const on = sortBy === o;
    return <button key={o} type="button" aria-pressed={on} onClick={() => {
      setSortBy(o);
      sortTables(o);
    }} style={{
      padding: '6px 10px',
      borderRadius: '8px',
      border: '1px solid ' + (on ? 'var(--sf-accent)' : 'var(--sf-border)'),
      background: 'var(--sf-bg)',
      color: on ? 'var(--sf-text)' : 'var(--sf-text-3)',
      fontSize: '13px',
      cursor: 'pointer'
    }}>
                  {o.charAt(0).toUpperCase() + o.slice(1)}
                </button>;
  })}
          </div>}
        </div>
        <div aria-live="polite" style={{
    margin: '8px 0 0',
    fontSize: '13px',
    color: 'var(--sf-text-3)',
    minHeight: '1px'
  }}>
          {q.trim() === '' && !facetActive ? <>{counts.total} {nounText}</> : counts.shown === 0 ? <>
                {q.trim() === '' ? 'No ' + nounText + ' match the selected filters.' : facetActive ? 'No ' + nounText + ' match \u201c' + q + '\u201d with the selected filters.' : 'No ' + nounText + ' match \u201c' + q + '\u201d.'}{' '}
                <button type="button" onClick={clearAll} style={{
    background: 'none',
    border: 'none',
    padding: 0,
    color: 'var(--sf-accent)',
    cursor: 'pointer',
    font: 'inherit',
    textDecoration: 'underline'
  }}>
                  Clear filters
                </button>
                {children ? <> {children}</> : null}
              </> : <>
                Showing {counts.shown} of {counts.total} {nounText}
              </>}
        </div>
      </div>
    </>;
};

<BackToIndex href="#all-settings" label="Back to index" />

This reference page lists each key Claude Code reads from a settings file, plus the [short group of keys](#global-config-settings) it keeps in `~/.claude.json` instead. To pick a file, or check precedence, start with [Settings files and precedence](/docs/en/settings).

<span id="available-settings" />

<span id="scopes" />

<span id="all-settings" />

## Settings index

Every key below links to its entry. Scope lists the [files](/docs/en/settings#settings-files-and-who-they-affect) it can go in: `User` is `~/.claude/settings.json`, `Project` is `.claude/settings.json`, `Local` is `.claude/settings.local.json`, and `Managed` is [what your organization deploys](/docs/en/managed-settings). `Any file` means all four, and `Global config` means [`~/.claude.json`](#global-config-settings).

<ReferenceFilter
  noun="settings"
  placeholder="Filter settings by key or purpose"
  facetOrder={{ scope: ["Any file", "User, local, or managed", "User or managed", "Managed", "Global config"] }}
  columnHelp={{
topic: "The section of this page that holds the entry. Use Sort by to group the table by topic.",
scope: "Which settings files can set the key: user (~/.claude/settings.json), project (.claude/settings.json), local (.claude/settings.local.json), or managed (deployed by your organization). Global config keys are in ~/.claude.json instead.",
}}
/>

| Key | Description | Topic | Scope |
| :- | :- | :- | :- |
| [`advisorModel`](#advisormodel) | Pick which model answers when Claude asks the [advisor tool](/docs/en/advisor) | Model and responses | Any file |
| [`agent`](#agent) | Start every session as a named [subagent](/docs/en/sub-agents) with its prompt, tools, and model | Agents, sessions, and worktrees | Any file |
| [`agentPushNotifEnabled`](#agentpushnotifenabled) | Let Claude send a [push notification to your phone](/docs/en/remote-control#mobile-push-notifications) when it decides to | Remote, desktop, and notifications | Any file |
| [`allowAllClaudeAiMcps`](#allowallclaudeaimcps) | Load the [claude.ai connectors](/docs/en/mcp) Claude Code fetches itself alongside a deployed [`managed-mcp.json`](/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) | MCP | Managed |
| [`allowClaudeInChromeWithManagedMcp`](#allowclaudeinchromewithmanagedmcp) | Let the built-in [Claude in Chrome](/docs/en/chrome) server run alongside a deployed [`managed-mcp.json`](/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) | MCP | Managed |
| [`allowedChannelPlugins`](#allowedchannelplugins) | Replace the default allowlist of [channel plugins](/docs/en/channels#restrict-which-channel-plugins-can-run) that can push messages | Plugins and skills | Managed |
| [`allowedHttpHookUrls`](#allowedhttphookurls) | Limit which URLs [HTTP hooks](/docs/en/hooks) can target | Hooks and automation | Any file |
| [`allowedMcpServers`](#allowedmcpservers) | Allowlist which [MCP servers](/docs/en/mcp) users can add | MCP | Any file |
| [`allowedProviders`](#allowedproviders) | Limit which [API providers](/docs/en/third-party-integrations) a machine may use | Authentication and providers | Managed |
| [`allowManagedHooksOnly`](#allowmanagedhooksonly) | Run only the [hooks](/docs/en/hooks) your organization deploys | Hooks and automation | Managed |
| [`allowManagedMcpServersOnly`](#allowmanagedmcpserversonly) | Make the managed [MCP](/docs/en/mcp) allowlist the only one that applies | MCP | Managed |
| [`allowManagedPermissionRulesOnly`](#allowmanagedpermissionrulesonly) | Make [managed settings](/docs/en/managed-settings) the only settings source of [permission rules](/docs/en/permissions#managed-settings) | Permission settings | Managed |
| [`alwaysThinkingEnabled`](#alwaysthinkingenabled) | Turn [extended thinking](/docs/en/model-config#extended-thinking) off for every session | Model and responses | Any file |
| [`apiKeyHelper`](#apikeyhelper) | Generate the [API credential](/docs/en/authentication#credential-management) with your own command | Authentication and providers | Any file |
| [`askUserQuestionTimeout`](#askuserquestiontimeout) | Let an unanswered question [auto-continue](/docs/en/tools-reference#question-auto-continue-timeout) after idle time | Interface and terminal | User or managed |
| [`appendPlugins`](#appendplugins) | Run your organization's [mods](/docs/en/plugins/mods/admin) after every mod a user installs | Plugins and skills | User or managed |
| [`attribution`](#attribution) | Customize the attribution Claude Code adds to commits and pull requests | Git and attribution | Any file |
| [`attribution.commit`](#attribution-commit) | Change or hide the trailer Claude Code adds to commits | Git and attribution | Any file |
| [`attribution.pr`](#attribution-pr) | Change or hide the attribution line in pull request descriptions | Git and attribution | Any file |
| [`attribution.sessionUrl`](#attribution-sessionurl) | Omit the claude.ai session link from [cloud](/docs/en/claude-code-on-the-web) and [Remote Control](/docs/en/remote-control) commits | Git and attribution | Any file |
| [`autoCompactEnabled`](#autocompactenabled) | Turn [automatic compaction](/docs/en/context-window) off or on | Memory and context | Any file |
| [`autoCompactWindow`](#autocompactwindow) | Set how full the context gets before Claude Code [compacts](/docs/en/context-window) | Memory and context | Any file |
| [`autoConnectIde`](#autoconnectide) | Connect to a running [VS Code](/docs/en/vs-code) or [JetBrains](/docs/en/jetbrains#from-external-terminals) IDE automatically from an external terminal | Global config settings | Global config |
| [`autoContinueAtUsageLimit`](#autocontinueatusagelimit) | Wait in the open session and [continue the task automatically](/docs/en/interactive-mode#wait-for-a-usage-limit-to-reset) after a claude.ai usage limit resets | Interface and terminal | User or managed |
| [`autoInstallIdeExtension`](#autoinstallideextension) | Turn off automatic install of the [IDE extension](/docs/en/vs-code#install-the-extension) from a VS Code terminal | Global config settings | Global config |
| [`autoMemoryDirectory`](#automemorydirectory) | Store [auto memory](/docs/en/memory#auto-memory) in a directory you choose | Memory and context | Any file |
| [`autoMemoryEnabled`](#automemoryenabled) | Turn [auto memory](/docs/en/memory#auto-memory) off or on | Memory and context | Any file |
| [`autoMode`](#automode) | Add your own allow and deny rules to the [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) classifier | Permission settings | User or managed |
| [`autoMode.classifyAllShell`](#automode-classifyallshell) | Send every shell command through the [auto mode classifier](/docs/en/permission-modes#what-the-classifier-blocks-by-default), even ones a narrow allow rule matches | Permission settings | User or managed |
| [`autoScrollEnabled`](#autoscrollenabled) | [Follow new output](/docs/en/fullscreen#auto-follow) to the bottom in fullscreen rendering | Interface and terminal | Any file |
| [`autoUpdatesChannel`](#autoupdateschannel) | Follow the stable [release channel](/docs/en/setup#configure-release-channel) instead of latest | Updates and versioning | Any file |
| [`availableModels`](#availablemodels) | [Restrict which models](/docs/en/model-config#restrict-model-selection) people can pick | Model and responses | Any file |
| [`availableModelsMatch`](#availablemodelsmatch) | Make each `availableModels` model ID entry [permit only the version it names](/docs/en/model-config#block-specific-models-or-versions) | Model and responses | Managed |
| [`awaySummaryEnabled`](#awaysummaryenabled) | Turn off the [session recap](/docs/en/interactive-mode#session-recap) shown when you come back to the terminal | Remote, desktop, and notifications | Any file |
| [`awsAuthRefresh`](#awsauthrefresh) | Refresh expired [Bedrock credentials](/docs/en/amazon-bedrock#advanced-credential-configuration) in `.aws` with your own command | Authentication and providers | Any file |
| [`awsCredentialExport`](#awscredentialexport) | Supply [Bedrock credentials](/docs/en/amazon-bedrock#advanced-credential-configuration) as JSON from your own command | Authentication and providers | Any file |
| [`axScreenReader`](#axscreenreader) | Render [screen-reader friendly output](/docs/en/accessibility) | Interface and terminal | Any file |
| [`bashEditDiffEnabled`](#basheditdiffenabled) | Record the [files that changed while a Bash command ran](/docs/en/hooks#bash) in every permission mode | Interface and terminal | User or managed |
| [`bashOutputMaxChars`](#bashoutputmaxchars) | Set how much of a successful command's [output](/docs/en/tools-reference#output-limits) Claude receives inline | Memory and context | Any file |
| [`blockedMarketplaces`](#blockedmarketplaces) | Block [plugin marketplace](/docs/en/plugins/overview) sources for your organization | Plugins and skills | Managed |
| [`browserExternalPageTools`](#browserexternalpagetools) | Keep Claude's tools off external pages in the [desktop](/docs/en/desktop) Browser pane | Tools | Managed |
| [`channelsEnabled`](#channelsenabled) | Allow [channels](/docs/en/channels#enable-channels-for-your-organization) for your organization | Plugins and skills | Managed |
| [`claudeInChromeDefaultEnabled`](#claudeinchromedefaultenabled) | Turn on [Chrome integration](/docs/en/chrome) when a session starts, in the interactive CLI and the VS Code extension | Global config settings | Global config |
| [`claudeMd`](#claudemd) | Inject organization-wide [CLAUDE.md](/docs/en/memory#deploy-organization-wide-claude-md) instructions from managed settings | Memory and context | Managed |
| [`claudeMdExcludes`](#claudemdexcludes) | Skip specific [CLAUDE.md](/docs/en/memory#exclude-specific-claude-md-files) files when memory loads | Memory and context | Any file |
| [`cleanupPeriodDays`](#cleanupperioddays) | Choose how many days Claude Code keeps [transcripts](/docs/en/data-usage#data-retention) before deleting them | Privacy and telemetry | Any file |
| [`companyAnnouncements`](#companyannouncements) | Show your organization's announcements at startup | Interface and terminal | Any file |
| [`copyFullResponse`](#copyfullresponse) | Make [`/copy`](/docs/en/commands) copy the full response without showing the code block picker | Global config settings | Global config |
| [`copyOnSelect`](#copyonselect) | Turn off automatic copying of text you select with the mouse in [fullscreen rendering](/docs/en/fullscreen#use-the-mouse) and agent view | Global config settings | Global config |
| [`crossSessionInbound`](#crosssessioninbound) | Choose whether Claude Code delivers [messages from your other sessions](/docs/en/cross-session-messaging#control-inbound-messages), shows a notice without delivering them, or refuses them | Agents, sessions, and worktrees | Any file |
| [`defaultShell`](#defaultshell) | Choose whether Bash or PowerShell runs the shell commands you type with the [`!` prefix](/docs/en/interactive-mode#shell-mode-with-prefix) | Interface and terminal | Any file |
| [`defaultToAgentsView`](#defaulttoagentsview) | Open [agent view](/docs/en/agent-view) instead of a new conversation when you run `claude` with no arguments | Global config settings | Global config |
| [`deniedMcpServers`](#deniedmcpservers) | Block specific [MCP servers](/docs/en/mcp) by URL, command, or name | MCP | Any file |
| [`deniedModels`](#deniedmodels) | [Block specific models](/docs/en/model-config#block-specific-models-or-versions), even ones `availableModels` permits | Model and responses | Managed |
| [`desktopSessionCleanupPeriodDays`](#desktopsessioncleanupperioddays) | Set an age limit in days for [Claude Desktop and Cowork transcripts](/docs/en/claude-directory#cleaned-up-automatically) | Privacy and telemetry | User or managed |
| [`dialogExpiry`](#dialogexpiry) | Set how long Claude Code waits for [Remote Control](/docs/en/remote-control) or an SDK host to answer a forwarded dialog before it cancels the dialog | Interface and terminal | User or managed |
| [`diffTool`](#difftool) | Choose whether Claude's proposed file changes open in the [VS Code](/docs/en/vs-code) or [JetBrains](/docs/en/jetbrains#features) diff viewer or stay in the terminal | Global config settings | Global config |
| [`disableAgentView`](#disableagentview) | Turn off background agents and [agent view](/docs/en/agent-view) | Agents, sessions, and worktrees | Any file |
| [`disableAllHooks`](#disableallhooks) | Turn off [hooks](/docs/en/hooks), a custom [status line](/docs/en/statusline), and a custom [`@` file suggestion](/docs/en/interactive-mode#quick-commands) command at once | Hooks and automation | Any file |
| [`disableArtifact`](#disableartifact) | Deprecated; use `enableArtifact` to turn the [Artifact tool](/docs/en/artifacts) off | Remote, desktop, and notifications | Any file |
| [`disableAutoMode`](#disableautomode) | Remove [auto mode](/docs/en/permission-modes#eliminate-prompts-with-auto-mode) from the permission mode cycle | Permission settings | Any file |
| [`disableBrowserExternalNavigation`](#disablebrowserexternalnavigation) | Limit the [desktop](/docs/en/desktop) Browser pane to localhost for people and Claude | Tools | Managed |
| [`disableBundledSkills`](#disablebundledskills) | Turn off the [skills](/docs/en/skills#bundled-skills) and [workflows](/docs/en/workflows) included with Claude Code | Plugins and skills | Any file |
| [`disableClaudeAiConnectors`](#disableclaudeaiconnectors) | Turn off [claude.ai connectors](/docs/en/mcp#disable-claude-ai-connectors) so Claude Code doesn't fetch them | MCP | Any file |
| [`disableCommandPluginSources`](#disablecommandpluginsources) | Block [plugins](/docs/en/plugins/overview) that install by running a marketplace-declared command | Plugins and skills | Managed |
| [`disableDeepLinkRegistration`](#disabledeeplinkregistration) | Stop Claude Code from registering the [`claude-cli://` handler](/docs/en/deep-links) | Remote, desktop, and notifications | Any file |
| [`disableDesktopLocalSessions`](#disabledesktoplocalsessions) | Turn off [Desktop Code sessions](/docs/en/desktop#local-sessions-on-managed-devices) that run on the device, leaving SSH to other hosts and cloud | Remote, desktop, and notifications | Managed |
| [`disabledMcpjsonServers`](#disabledmcpjsonservers) | Reject specific servers from a project's [`.mcp.json`](/docs/en/mcp#project-scope) | MCP | Any file |
| [`disableMobileSimulatorTools`](#disablemobilesimulatortools) | Block Claude's tools in the [desktop](/docs/en/desktop) iOS Simulator pane | Tools | Managed |
| [`disableRemoteControl`](#disableremotecontrol) | Turn off [Remote Control](/docs/en/remote-control) everywhere it can start | Remote, desktop, and notifications | Any file |
| [`disableSideloadFlags`](#disablesideloadflags) | Reject the CLI flags that sideload [plugins](/docs/en/plugins/overview), [subagents](/docs/en/sub-agents), and [MCP servers](/docs/en/mcp) | Enterprise and managed settings | Managed |
| [`disableSkillShellExecution`](#disableskillshellexecution) | Stop [skills](/docs/en/skills) and custom commands from running inline shell | Plugins and skills | Any file |
| [`disableWorkflows`](#disableworkflows) | Turn [dynamic workflows](/docs/en/workflows) off for everyone; use `enableWorkflows` for yourself | Hooks and automation | Any file |
| [`editorMode`](#editormode) | Use [vim key bindings](/docs/en/interactive-mode#vim-editor-mode) in the input prompt | Interface and terminal | Any file |