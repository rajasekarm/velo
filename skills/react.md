---
name: react
description: React with TypeScript, hooks-first, accessibility-first. Custom hooks, error boundaries, context vs Zustand vs TanStack Query, lazy loading, profiling-driven memoization.
---
# React

**Scope:** React with TypeScript, hooks-first, accessibility-first.

## Rules
- Components are small, focused, and composable — one responsibility each
- Custom hooks extract reusable logic out of components
- `React.memo`, `useMemo`, `useCallback` only when profiling shows a need — not by default
- No prop drilling past 2 levels — use context or composition
- Error boundaries around every async boundary
- Named exports, barrel index files per feature directory
- All user-facing text must be accessible (proper labels, alt text, roles)

## State Management
- React context for app-level state
- Zustand for complex client state
- TanStack Query for server state (caching, refetching, optimistic updates)

## Performance
- Bundle splitting via lazy loading (`React.lazy` + `Suspense`)
- Core Web Vitals awareness (LCP, FID, CLS)
- Avoid unnecessary re-renders — profile before optimising

## Accessibility
- ARIA labels on interactive elements
- Keyboard navigation for all flows
- Screen reader testing for critical paths
- Colour contrast meets WCAG AA

## TypeScript
- Strict mode — no `any`
- Proper generics and discriminated unions for state
- Props interfaces co-located with components

## Verification
```bash
npx tsc --noEmit
```
