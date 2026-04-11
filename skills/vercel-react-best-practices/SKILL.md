<!-- SOURCE: https://github.com/vercel-labs/agent-skills/blob/main/skills/react-best-practices/AGENTS.md -->
<!-- UPDATED: 2026-04-11 -->
<!-- TO UPDATE: ./scripts/sync-agent-skill.sh vercel-react-best-practices vercel-labs/agent-skills skills/react-best-practices/AGENTS.md -->

# Vercel React Best Practices

**8 categories. Read `rules/<file>` for full examples on any category.**

## 1. Eliminating Waterfalls — `rules/01-eliminating-waterfalls.md`
- Check Cheap Conditions Before Async Flags
- Defer Await Until Needed
- Dependency-Based Parallelization
- Prevent Waterfall Chains in API Routes
- Promise.all() for Independent Operations
- Strategic Suspense Boundaries

## 2. Bundle Size Optimization — `rules/02-bundle-size-optimization.md`
- Avoid Barrel File Imports
- Conditional Module Loading
- Defer Non-Critical Third-Party Libraries
- Dynamic Imports for Heavy Components
- Preload Based on User Intent

## 3. Server-Side Performance — `rules/03-server-side-performance.md`
- Authenticate Server Actions Like API Routes
- Avoid Duplicate Serialization in RSC Props
- Avoid Shared Module State for Request Data
- Cross-Request LRU Caching
- Hoist Static I/O to Module Level
- Minimize Serialization at RSC Boundaries
- Parallel Data Fetching with Component Composition
- Parallel Nested Data Fetching
- Per-Request Deduplication with React.cache()
- Use after() for Non-Blocking Operations

## 4. Client-Side Data Fetching — `rules/04-client-side-data-fetching.md`
- Deduplicate Global Event Listeners
- Use Passive Event Listeners for Scrolling Performance
- Use SWR for Automatic Deduplication
- Version and Minimize localStorage Data

## 5. Re-render Optimization — `rules/05-re-render-optimization.md`
- Calculate Derived State During Rendering
- Defer State Reads to Usage Point
- Do not wrap a simple expression with a primitive result type in useMemo
- Don't Define Components Inside Components
- Extract Default Non-primitive Parameter Value from Memoized Component to Constant
- Extract to Memoized Components
- Narrow Effect Dependencies
- Put Interaction Logic in Event Handlers
- Split Combined Hook Computations
- Subscribe to Derived State
- Use Functional setState Updates
- Use Lazy State Initialization
- Use Transitions for Non-Urgent Updates
- Use useDeferredValue for Expensive Derived Renders
- Use useRef for Transient Values

## 6. Rendering Performance — `rules/06-rendering-performance.md`
- Animate SVG Wrapper Instead of SVG Element
- CSS content-visibility for Long Lists
- Hoist Static JSX Elements
- Optimize SVG Precision
- Prevent Hydration Mismatch Without Flickering
- Suppress Expected Hydration Mismatches
- Use Activity Component for Show/Hide
- Use defer or async on Script Tags
- Use Explicit Conditional Rendering
- Use React DOM Resource Hints
- Use useTransition Over Manual Loading States

## 7. JavaScript Performance — `rules/07-javascript-performance.md`
- Avoid Layout Thrashing
- Build Index Maps for Repeated Lookups
- Cache Property Access in Loops
- Cache Repeated Function Calls
- Cache Storage API Calls
- Combine Multiple Array Iterations
- Defer Non-Critical Work with requestIdleCallback
- Early Length Check for Array Comparisons
- Early Return from Functions
- Hoist RegExp Creation
- Use flatMap to Map and Filter in One Pass
- Use Loop for Min/Max Instead of Sort
- Use Set/Map for O(1) Lookups
- Use toSorted() Instead of sort() for Immutability

## 8. Advanced Patterns — `rules/08-advanced-patterns.md`
- Do Not Put Effect Events in Dependency Arrays
- Initialize App Once, Not Per Mount
- Store Event Handlers in Refs
- useEffectEvent for Stable Callback Refs
