---
name: react-effects
description: When NOT to use useEffect in React. Derived state, event handlers, useMemo patterns, syncing with external systems only.
---
# React Effects — When Not to Use useEffect

## The rule

Effects are for syncing with **external systems** only (APIs, browser APIs, third-party widgets, subscriptions).

Ask before writing a `useEffect`: *does this run because the component displayed, or because the user did something?*
- Displayed → Effect (maybe)
- User action → event handler, not an Effect

---

## Common misuses and fixes

### Derived state
Don't compute values via Effect + setState. Compute during render.

```tsx
// ❌
useEffect(() => {
  setFullName(firstName + ' ' + lastName)
}, [firstName, lastName])

// ✅
const fullName = firstName + ' ' + lastName
```

### Expensive calculations
Use `useMemo`, not Effect.

```tsx
// ❌
useEffect(() => {
  setFiltered(items.filter(expensiveFilter))
}, [items])

// ✅
const filtered = useMemo(() => items.filter(expensiveFilter), [items])
```

### User event side effects
Handle in the event handler, not an Effect watching for state change.

```tsx
// ❌
useEffect(() => {
  if (product.isInCart) showNotification('Added!')
}, [product])

// ✅
function handleBuyClick() {
  addToCart(product)
  showNotification('Added!')
}
```

### Reset state when prop changes
Pass a `key` prop — React resets the component automatically.

```tsx
// ❌
useEffect(() => {
  setComment('')
}, [userId])

// ✅
<ProfilePage key={userId} userId={userId} />
```

### Notify parent on change
Call the parent callback directly in the event handler.

```tsx
// ❌
useEffect(() => {
  onChange(selected)
}, [selected])

// ✅
function handleSelect(value) {
  setSelected(value)
  onChange(value)
}
```

### Chained state updates
Collapse into a single event handler — don't chain Effects.

```tsx
// ❌
useEffect(() => setB(a + 1), [a])
useEffect(() => setC(b * 2), [b])

// ✅
function handleAction() {
  const b = a + 1
  const c = b * 2
  setB(b)
  setC(c)
}
```

---

## When Effects ARE correct

- Fetching data (with cleanup for race conditions)
- Setting up subscriptions / event listeners
- Syncing with third-party libraries
- Browser APIs that need cleanup
