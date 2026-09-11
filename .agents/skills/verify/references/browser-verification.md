# Browser verification providers

Load only for browser criteria selected by Verify. Shared by Claude Code and Codex, this guide supports Chrome DevTools MCP and Playwriter; neither is installed or bundled by Velo.

## Before checking

1. Read the selected criteria and verification setup, including every case named for each criterion. For a Run call, select only the criteria due in its milestone. Keep the expected results unchanged.
2. Select the provider named by the user or approved plan. If no provider is pinned, use an available configured Chrome DevTools MCP or Playwriter connection that supports the required observations, and announce the selection. Do not assume availability from a tool name in a document. A pinned unavailable provider is blocked unless an allowed fallback or explicit user authorization permits another.
3. Load only the selected provider's documentation: for **Chrome DevTools MCP**, follow its actual exposed tool schemas and installed skill or [official guide](https://developer.chrome.com/docs/devtools/agents/get-started); for **Playwriter**, prefer its installed CLI plus skill, with MCP supported when configured, and follow its installed skill or [agent reference](https://playwriter.dev/docs/skill). Playwriter extension mode needs its Chrome extension and enabled connection; Chrome DevTools MCP uses its own configured browser connection and does not require the Playwriter extension. Missing tools, connection, app access, or test data means blocked. Do not install software or change user configuration implicitly.
4. Start or confirm the app using the authorized verification setup. Check that the target serves the intended implementation, not an unrelated deployment or stale build. Record the URL and code revision, including whether local changes are uncommitted. If this cannot be established, report blocked.
5. Use a task-owned browser page/session and the specified test data. Keep actions within the authorized application and scenarios. Never read unrelated tabs or credentials; do not send real messages, make purchases, or change production data as test setup without explicit authorization.

## Observe, act, compare

- Inspect the page before choosing locators; use observed accessible roles, labels, or stable selectors. Perform the user actions through the UI and observe the resulting state. Do not modify application state with page evaluation or mock the very outcome being verified to manufacture a pass.
- For each case, compare actual values with the criterion's expected result. A loaded page, successful click, screenshot alone, or HTTP 200 is not proof that a feature works. Check the specific behavior, including negative/empty cases the plan names.
- Reset to the defined initial state between cases when necessary. Wait for observable UI conditions using the selected provider's supported APIs rather than arbitrary sleeps.
- Use snapshots, rendered text, counts, ordering, and screenshots where useful as evidence. Browser-side checks prove only what was observed there; required persistence or backend guarantees also need the plan's API/command checks.
- Record `pass` only when every required case for that criterion matched. Record `fail` for an observed mismatch and `blocked` when the check could not be performed reliably. Never turn unavailable tooling or login failures into a pass.

## Evidence and handback

Return results using the [Verify report format](../../../../commands/verify.md#4-report-and-return). Include criterion, selected browser provider, target, revision, actions, expected/observed results, and evidence. Concise observations are sufficient when they prove the claim; screenshots are optional and require an authorized output location. This guide creates no new report-file or plan-write permission.

Do not fix failures here. Run records returned evidence and handles its repair/pause loop; standalone Verify reports findings and stops. Recheck affected criteria after relevant code changes; never reuse a stale pass. Browser checks do not replace independent review or required API/command checks.

Setup references: [Chrome DevTools MCP](https://developer.chrome.com/docs/devtools/agents/get-started), [Playwriter installation](https://playwriter.dev/docs/installation), [Playwriter CLI/MCP options](https://playwriter.dev/docs/mcp-setup). Use the installed tool version's instructions rather than copying setup commands into Velo's workflow.
