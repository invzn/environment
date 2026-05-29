# Go Style Guide

Standards derived from the Google Go Style Guide, Effective Go, the Uber Go Style Guide, and 100 Go Mistakes and How to Avoid Them. All Go agents must follow these conventions.

This guide assumes Go 1.18+ (generics). Version-specific behavior is noted where relevant.

Sources: [Google Go Style Guide](https://google.github.io/styleguide/go/), [Effective Go](https://go.dev/doc/effective_go), [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md), 100 Go Mistakes and How to Avoid Them (Teiva Harsanyi). This guide is authoritative; when it conflicts with the source guides, follow this guide.

## Agent Conduct

These rules govern how a Go agent applies the rest of this guide. They take precedence over any specific style rule below.

- Stay within the requested scope. Do not refactor, rename, add validation, add tests, add comments, or extract helpers beyond what the task explicitly asked for. A bug fix changes only what's needed to fix the bug. A feature adds only what's needed for the feature. If you notice unrelated issues, mention them in your response — do not fix them silently.
- Match the existing codebase before applying this guide. If surrounding code uses an older idiom (e.g., pre-1.21 patterns, custom logger, no slog, value receivers where this guide prefers pointers), match the existing style within the file/package and call out the divergence in your response. Do not silently modernize unrelated code.
- Apply rules at the boundaries this guide names. Apply a rule only inside the construct it targets (function, package, type, etc.). Do not extrapolate a rule to adjacent constructs because they "feel similar."
- The 🔧 marker means a linter exists for the rule — it does not relieve you of following the rule. Write code that already conforms; do not rely on CI to fix your output.
- When two rules conflict on a specific case, prefer the rule that is more local (file-level over package-level), more specific (named construct over general principle), and explicitly marked as overriding.

## Recommended Linters

Many rules in this guide can be enforced automatically. Recommended toolchain:
- `goimports` — import grouping and formatting
- `go vet` — compiler-adjacent correctness checks
- `staticcheck` — comprehensive static analysis (replaces `golint`)
- `revive` — configurable linting (naming, receiver names, exported docs)
- `errcheck` — unchecked error returns
- `errorlint` — `%w` wrapping, `errors.Is`/`errors.As` usage
- `forcetypeassert` — single-value type assertions
- `gocritic` — opinionated style and performance checks
- `gocyclo` / `gocognit` — cyclomatic/cognitive complexity
- `gosec` — security-focused analysis
- `shadow` — variable shadowing detection

Rules that can be linter-enforced are marked with 🔧 below.

## Version Notes
- Go 1.13+: `0o` octal prefix, number underscores
- Go 1.16+: `//go:embed` for embedding static assets
- Go 1.18+: generics, `strings.Clone()`, native fuzzing, workspaces (`go.work`)
- Go 1.19+: `GOMEMLIMIT` soft memory limit
- Go 1.20+: `errors.Join` for aggregating multiple errors
- Go 1.21+: `log/slog` structured logging in stdlib, `context.AfterFunc`, `min`/`max`/`clear` builtins
- Go 1.22+: range loop variables scoped per iteration (see Control Flow)
- Go 1.23+: unreferenced timers eligible for GC before firing
- Go 1.24+: `b.Loop()` for benchmarks

---

# Foundations

## Naming

- Use MixedCaps for all names; unexported names start lowercase
- 🔧 Acronyms in names should be fully capitalized when exported: `HTTPServer`, `URLPath`, `XMLParser`; lowercase when unexported: `httpClient`, `urlParser`. Never mixed case: ❌ `HttpServer`, `UrlPath`, `HTTPserver` (`revive: var-naming`)
- 🔧 Getters: `obj.Name()` not `obj.GetName()`; setters: `obj.SetName()` (`revive: get-return`)
- 🔧 Receiver names: short (1-2 chars), consistent across methods, never `this` or `self` (`revive: receiver-naming`)
- Interface names: single-method interfaces use `-er` suffix (`Reader`, `Writer`)
- Use full descriptive names by default. Use short names only for: loop indexes (`i`), receivers (1-2 chars), and standard io variables (`r`, `w`, `buf`).
- Package names: lowercase, no underscores, singular, ≤10 characters where possible (stdlib exceptions: `strings`, `bytes`, `errors`).
- Never create utility packages (`util`, `common`, `helpers`, `base`) — they become dumping grounds. Name packages by what they provide: ❌ `util.TrimPrefix()` → ✅ `stringutil.TrimPrefix()`.
- Error variables: `ErrFoo` (e.g., `var ErrNotFound = errors.New(...)`).
- Error types: `FooError` (e.g., `type NotFoundError struct{...}`).

## Imports

- 🔧 Group in order: stdlib, third-party, internal; blank line between groups (`goimports`)
- Avoid dot imports except in specific test scenarios (e.g., DSL-style test packages, `gomock`)
- Avoid renaming imports unless resolving conflicts
- Use blank imports (`_ "pkg"`) primarily in main or test packages; rare exception for library packages that aggregate side-effect imports (e.g., database driver registration)

## Error and Failure Handling

- 🔧 Handle errors immediately after the call; don't defer error checks (`errcheck`)
- 🔧 Always use `%w` when wrapping, never `%v`. `%v` flattens the error to a string and breaks `errors.Is`/`errors.As` (`errorlint`).
- Always use `fmt.Errorf` (with `%w`) when adding context, even if the prefix string is static. `errors.New` is for creating *new* errors with no underlying cause.
- When to wrap vs. return as-is:

  | Scenario | Action | Example |
  |----------|--------|---------|
  | Application code, adding operation context | Wrap | `fmt.Errorf("load config %s: %w", path, err)` |
  | Library code, returning a sentinel error | Return as-is | `return ErrNotFound` |
  | Translating between error domains | Wrap + convert | `if errors.Is(err, os.ErrNotExist) { return ErrUserNotFound }` |
  | Error already has sufficient context | Return as-is | `return err` (e.g., well-wrapped errors from dependencies) |
- Use `errors.Join` (Go 1.20+) to aggregate multiple errors: `return errors.Join(err1, err2)` — useful for cleanup sequences, parallel operations, or multi-step validation where multiple failures should be reported
- Use sentinel errors (`var ErrNotFound = errors.New(...)`) for expected conditions that callers check with `errors.Is` — best for simple yes/no error identity (not found, unauthorized, timeout)
- Use custom error types (`type NotFoundError struct { ID string }`) when callers need to extract structured information with `errors.As` — best when the error carries context like IDs, HTTP status codes, or retry info
- When ignoring an error, document why with a comment.
- Always check `Close()` errors on writers/flushers (`os.File`, `zip.Writer`, `bufio.Writer`) — Close can fail with data loss.
- Checking `Close()` errors on readers is optional after a successful read (e.g., `http.Response.Body`).
- Pattern for deferred Close with error propagation:
  ```go
  defer func() { if cErr := f.Close(); cErr != nil && err == nil { err = cErr } }()
  ```
- 🔧 Use `errors.Is` for sentinel errors and `errors.As` for error types — never use `==` or type switch, as wrapping breaks direct comparison (`errorlint`)
- Prefer `errors.Is`/`errors.As` over calling `errors.Unwrap` directly — they traverse the full chain automatically.
- When implementing a custom error type that wraps another error, define `Unwrap() error`. For multi-error types, define `Unwrap() []error` (Go 1.20+, used by `errors.Join`).
- Don't log and return an error — pick one. Boundary code (HTTP handler, top-level main, signal handler) logs and consumes; everything inside returns. Example:
  ```go
  // ❌ logs AND returns — error gets logged twice up the stack
  log.Error("failed to save user", "err", err)
  return fmt.Errorf("save user: %w", err)

  // ✅ trace log (not the error), then return
  log.Debug("attempting user save", "userID", id)
  if err := store.Save(ctx, user); err != nil {
      return fmt.Errorf("save user %s: %w", id, err)
  }
  ```
- Don't use `panic` for normal error handling; never panic across API/library boundaries — callers can't reasonably recover
- Panic is appropriate for programmer errors and impossible states (e.g., unreachable code, failed type assertion in a type switch that covers all cases)
- `recover()` only works inside deferred functions — it returns `any` and needs a type assertion
- Use recover at the top of goroutines in servers to prevent one request from crashing the process

## Documentation

- 🔧 Doc comments on all exported names (`revive: exported`)
- Package comment in one file (usually `doc.go`)
- Start doc comments with the name being declared
- Use complete sentences ending with periods
- Use `Example` test functions for non-trivial usage documentation
- Avoid redundant comments like `// GetName gets the name` — if the code is clear, don't restate it

---

# Data Types and Declarations

## Declarations

- Use `var` for zero-value variables (`var s []int`), `:=` for non-zero (`s := make([]int, 0, n)`)
- Default to `var s []int` (nil slice) — `len()`, `append`, and `range` all work; `s == nil` is true.
- Use `s := []int{}` (empty, non-nil) when the slice will be JSON-marshaled and you need `[]` instead of `null` in the output.
- Group related declarations; separate unrelated ones. Group by logical relationship (e.g., all HTTP client config vars together) or by type (e.g., all error sentinels together)
- Initialize structs with field names: `T{Field: value}`, not positional
- Specify slice/map capacity with `make` when size is known
- Use `if err := fn(); err != nil` (initializer form) whenever the variable isn't read after the `if`. Use a function-scope `var err error` only when the same `err` identifier is reassigned and read across multiple non-initializer statements.
- 🔧 Don't shadow with `:=` in inner blocks. `err := otherFn()` inside an `if` creates a new `err` that hides the outer one (`shadow` analyzer, available standalone or via `golangci-lint`).
- 🔧 Always use two-value type assertions `v, ok := x.(T)` in production code — single-value form panics on mismatch. Exception: test code where a panic indicates a test failure (`forcetypeassert`). Example:
  ```go
  // ❌ panics if val is not string
  s := ctx.Value(key).(string)

  // ✅ safe — check ok before using
  s, ok := ctx.Value(key).(string)
  if !ok { return errors.New("expected string in context") }
  ```
- Design structs so the zero value is useful and valid (e.g., `sync.Mutex`, `bytes.Buffer` are ready without initialization)
- Avoid mutable package-level globals; use dependency injection instead
- Prefer concrete types or generics over `any` in APIs. Use `any` only when runtime type flexibility is genuinely needed (e.g., JSON unmarshaling, plugin systems, logging contexts)
- 🔧 Use `_` to explicitly mark ignored return values (`errcheck`).
- When ignoring an error with `_`, add a comment explaining why.
- Use `iota` for enumerations. Consider skipping zero value with `_ = iota` when zero should represent "unset" rather than a valid enum member
- Typed constants provide compile-time safety: `type Status int; const (Active Status = iota + 1; Inactive)` prevents accidental assignment from plain `int`
- Use `//go:generate stringer -type=Status` to auto-generate `String()` methods for enum types — avoids hand-maintaining string representations
- Prefer typed constants over untyped when the value represents a domain concept; use untyped constants for universal numeric/string literals shared across types
- Type embedding promotes ALL fields and methods — can accidentally satisfy interfaces or expose internal state
- Never embed sync types in public structs — exposes `Lock()`/`Unlock()`: ❌ `type Cache struct { sync.Mutex; data map[string]string }` → ✅ `type Cache struct { mu sync.Mutex; data map[string]string }`
- Use explicit fields instead of embedding when you want to hide methods or the embedded type is mutable state. Embedding is for composition, not inheritance

## Numeric Types

- Integer arithmetic can silently overflow — Go does NOT panic. For critical calculations, check before operations: `if a > math.MaxInt64 - b { return error }`
- Use `math/big` for arbitrary precision when overflow is unacceptable
- Float operations are not exact: `0.1 + 0.2 != 0.3` in binary. Never use `==` for floats; use tolerance: `math.Abs(a - b) < epsilon`
- For money/precise decimals, use integer cents or a decimal library — never floating point
- Leading zero creates octal: `010 = 8` not `10`. Prefer `0o` prefix for clarity: `0o10` (Go 1.13+). Use underscores for readability: `1_000_000`
- Use the `min` and `max` builtins (Go 1.21+) instead of manual comparisons or `math.Min`/`math.Max` (which require `float64` casts): `smallest := min(a, b, c)`. Works with any ordered type including integers and strings

## Slices and Maps

- Appending to a sub-slice can mutate the original's underlying array — use `copy` or full slice expressions (`s[low:high:max]`) to avoid side effects
- Slicing a large slice keeps the entire backing array alive — copy the needed data to a new slice to allow GC of the original
- Maps never shrink — deleting keys doesn't free memory. Recreate the map if it grew large and is now mostly empty
- Slices and maps cannot be compared with `==` (except to `nil`) — it's a compile error. Use `slices.Equal`/`maps.Equal` (Go 1.21+) for typed comparison, or `reflect.DeepEqual` for untyped comparison
- Don't assume map iteration order — it is randomized by the runtime
- `len()` works on nil slices/maps (returns 0) — use `len(s) == 0` to check for empty, not `s == nil`.
- Use the `clear` builtin (Go 1.21+) to zero out slices or delete all map entries: `clear(s)` sets all slice elements to their zero value (length unchanged); `clear(m)` removes all map keys. Useful for reusing allocated memory without reallocating

## Strings

- Strings are byte slices, not rune slices — `len(s)` returns bytes, not characters
- `for range s` iterates over runes; `for i := 0; i < len(s); i++` iterates over bytes — choose deliberately
- Use `[]rune(s)` when you need to index or manipulate individual characters
- Substrings share backing array with the original — slicing a large string keeps it all in memory. To release the original: `s2 := strings.Clone(largeString[start:end])` (Go 1.18+) or `s2 := string([]byte(largeString[start:end]))`

## Initialization

- Avoid `init()` — issues: error handling is limited (must panic or set global state), runs before tests (can't isolate), and forces global variables
- `init()` is acceptable for: side-effect imports (database drivers), static configuration that cannot fail, and package registration patterns
- Prefer explicit initialization functions that return errors over `init()`
- Use `sync.Once` for lazy initialization — prefer over `init()` or check-and-set patterns

---

# Control Flow and Functions

## Functions

- 🔧 Functions must not exceed 100 lines. Split before exceeding 60 lines unless the body is genuinely sequential (no branching) (`gocyclo`, `gocognit`).
- 🔧 Keep cyclomatic complexity ≤ 10 (hard cap 15). Split by separating validation, core logic, and formatting (`gocyclo`).
- Return early — handle errors and edge cases first (guard clauses). Keep the happy path left-aligned; avoid nesting deeper than 2-3 levels
- Avoid naked returns in named result parameters
- Use functional options for constructors with many optional parameters. Example:
  ```go
  type Option func(*Server)

  func WithTimeout(d time.Duration) Option {
      return func(s *Server) { s.timeout = d }
  }
  func WithLogger(l *slog.Logger) Option {
      return func(s *Server) { s.logger = l }
  }

  func NewServer(addr string, opts ...Option) *Server {
      s := &Server{addr: addr, timeout: 30 * time.Second} // defaults
      for _, opt := range opts {
          opt(s)
      }
      return s
  }

  // Usage
  srv := NewServer(":8080", WithTimeout(10*time.Second), WithLogger(logger))
  ```
- Accept interfaces, return concrete types. Parameters take interfaces (`io.Reader`); return values are concrete.
- Exceptions to "return concrete": the `error` interface, and factory functions that intentionally hide the implementation (`NewCache() Cache`).
- Define interfaces on the consumer side, not the producer — the package that uses the interface should define it, not the package that implements it
- Accept `io.Reader`/`io.Writer` instead of filenames or file paths — improves testability and composability
- Receiver kind: a type's methods all share the same receiver kind. Before adding a method, check the existing methods on the type — if any of them use a pointer receiver, the new method must too (and vice versa). This rule overrides the per-method preferences below. Only when defining the *first* method on a new type do you choose freely:
  1. Use a pointer receiver if the method mutates state, the struct contains sync types or resources (file handles, connections), or the struct is larger than a few words (~16-24 bytes on 64-bit).
  2. Use a value receiver only for small immutable types (e.g., `time.Time`, `netip.Addr`).
  3. When in doubt at this first-method stage, use a pointer receiver — it forces the rest of the type's methods to follow, which is the safer default.
- Never return a typed nil pointer from a function returning an interface — a nil pointer stored in an interface is NOT nil (the interface contains type info). Use explicit `return nil` instead of returning a typed nil variable
- Beware of named result parameters with defer — deferred closures capture named returns by reference, e.g. `defer func() { err = nil }()` with bare `return` silently overrides the error

## Control Flow

- Use `switch` over long `if-else` chains
- `break` in a `switch` or `select` breaks out of the switch/select, not an enclosing `for` loop — use a labeled break to exit the loop:
  ```go
  outer:
      for _, item := range items {
          switch item.Type {
          case "done":
              break outer // exits the for loop, not just the switch
          case "skip":
              break // exits only the switch, loop continues
          }
      }
  ```
- Range expression is evaluated once before the loop starts — range over an array copies the entire array; use a slice or pointer to avoid the copy
- Range loops copy values — modifying the loop variable doesn't modify the original collection. Use index access or pointer slices to mutate
- Go 1.22+ scopes range loop variables per iteration, so `&v` is safe.
- For Go <1.22 (or to stay compatible), taking `&v` in a range loop captures a single reused variable — all pointers end up at the last value. Fix: index iteration `for i := range items { item := &items[i] }`, or shadow inside the loop `v := v`.
- `defer` in a loop stacks up until function exit, not after each iteration — this causes resource leaks. Extract the loop body into a function or use explicit cleanup within the iteration

---

# Type System and Composition

## Generics

- Use generics for type-safe data structures and algorithms that operate on multiple types (e.g., `Min[T constraints.Ordered]`, `Map[K comparable, V any]`)
- If the logic is identical and only the type differs → use generics. If behavior varies by type → use an interface.
- Type parameter naming: single uppercase letters — `T` for general, `K`/`V` for key/value, `E` for element
- Use `comparable` constraint when map keys or `==` comparison is needed; use `any` only when no constraint is required. Example:
  ```go
  func Index[T comparable](s []T, target T) int {
      for i, v := range s {
          if v == target { return i } // requires comparable
      }
      return -1
  }
  ```
- Don't use generics just to avoid writing two similar functions — if there are only 2 concrete types, concrete functions are simpler
- Avoid complex constraint hierarchies — keep constraints small and composable

## Reflection

- Avoid reflection (`reflect` package) unless genuinely needed — it's slow, not type-safe, and makes code harder to understand
- Legitimate uses: serialization/deserialization (JSON, ORM), generic test utilities, dependency injection frameworks
- Prefer generics (Go 1.18+) over reflection for type-safe generic code
- Reflection-heavy code should be isolated in dedicated packages, not scattered throughout business logic

---

# Concurrency and Lifecycle

## Concurrency

### Common bugs (read first)

- `fmt.Sprintf`/`fmt.Errorf`/`log.Print*` with `%s` or `%v` can call `String()` on the value. If `String()` acquires a lock the caller already holds, the goroutine deadlocks against itself. Format outside the locked section, or have `String()` snapshot state under its own scoped lock.
- Concurrent `append` to the same slice is a data race — `append` mutates the slice header (len/cap) and may reallocate the backing array. Use separate slices per goroutine and merge after, or hold a mutex.
- Returning a slice or map from a mutex-protected method leaks the reference — callers can mutate without the lock. Return a copy.
- 🔧 Never copy sync types (`sync.Mutex`, `sync.WaitGroup`, `sync.Cond`, etc.) — always pass by pointer (`go vet -copylocks`).

### Choosing a primitive

- Channels orchestrate; mutexes serialize:
  - **Channels**: data ownership transfers, pipeline stages, fan-out/fan-in, signaling between goroutines
  - **Mutexes**: shared state with short critical sections (map updates, counters, caches)
  - **Atomic ops** (`sync/atomic`): single-value counters and flags — faster than mutexes for uncontended cases
  - Tiebreaker: transferring data → channel; protecting data → mutex.
- Use `sync.Cond` for "wait until condition becomes true" patterns. Don't poll with `time.Sleep`; use `cond.Wait()` + `cond.Broadcast()`.
- Use `sync.WaitGroup` for fan-out patterns.
- Use `errgroup` (`golang.org/x/sync/errgroup`) for goroutine groups that can fail.
- Use `context.Context` for cancellation and deadlines.
- Use `sync.Map` only for: (1) cache-like workloads with write-once-read-many keys, or (2) goroutines reading/writing non-overlapping key sets with minimal contention. Otherwise use `map` with `sync.RWMutex`.

### Goroutine lifecycle

- Start a goroutine only with a stop mechanism: context cancellation, a `done` channel, or an explicit shutdown method.
- Never launch fire-and-forget goroutines.

### Channels

- Use `chan struct{}` for signals, not `chan bool`.
- Default to unbuffered channels. Use buffered channels only with a specific size justification.
- Nil channels block forever on send and receive — useful for dynamically disabling `select` cases.
- Use `select` with `default` for non-blocking operations. Don't simulate non-blocking with `time.After(1 * time.Nanosecond)`.
- `select` with multiple ready cases picks randomly. For priority, use a nested `select`: try high-priority channels first with a `default`, then fall through to a full `select`.

### Other

- Share by communicating, not by sharing: pass data through channels rather than locking shared memory when coordinating goroutines.
- A data race is two or more goroutines accessing the same memory concurrently with at least one write and no synchronization. Concurrent reads alone are safe.

## Context

- Pass `context.Context` as the first function parameter, not stored in structs. Exception: structs that exist only for the lifetime of a single request (e.g., an HTTP handler struct created per-request)
- Use `context.WithCancel`, `context.WithTimeout`, or `context.WithDeadline` for goroutine lifecycle management
- Never pass `nil` context — use `context.Background()` or `context.TODO()` if you don't have one
- Use custom unexported key types for context values — never use strings or built-in types as keys, since package-local types are unique even if structurally identical, preventing key collisions across packages. Example:
  ```go
  type ctxKey struct{}
  var userIDKey = ctxKey{}

  // Store
  ctx = context.WithValue(ctx, userIDKey, userID)

  // Retrieve
  if id, ok := ctx.Value(userIDKey).(string); ok {
      log.Info("processing request", "userID", id)
  }
  ```
- Use `context.AfterFunc(ctx, fn)` to register cleanup that runs on cancellation, instead of spawning a goroutine on `<-ctx.Done()`. It returns a `stop` function to cancel the callback if no longer needed:
  ```go
  stop := context.AfterFunc(ctx, func() { conn.Close() })
  defer stop()
  ```
- Don't use context for passing optional function parameters — use functional options or explicit arguments

## Time

- Use `time.Duration` for durations, never bare `int` or `int64`
- Use `time.Time` for instants, never bare `int64` for unix timestamps
- Pass `time.Duration` to functions, not `int` with implicit units
- Use `time.NewTimer` + `Reset`/`Stop` in long-running or high-frequency loops; never `time.After`.
- `time.After` is fine in short, bounded loops (e.g., 3 retries).
- Background: pre-1.23 `time.After` leaked timers until they fired; 1.23+ GCs them. The rule above holds regardless.

---

# Testing

- Use table-driven tests with subtests (`t.Run`)
- Test function names: `TestFunctionName_Scenario`
- Use `t.Helper()` in test helper functions
- Use `testdata/` directory for test fixtures; use `t.TempDir()` for temporary directories that auto-cleanup after the test
- Use `t.Cleanup(fn)` instead of `defer fn()` for test teardown. It runs in LIFO order, works correctly with `t.Parallel()`, and runs even if the test panics.
- In tests, use `t.Fatal`/`t.Fatalf` for unrecoverable failures, never `panic`.
- Use `cmp.Diff` from `go-cmp` for comparing complex structs. For floats, use `cmpopts.EquateApprox`. For projects avoiding third-party test deps, use `reflect.DeepEqual` with manual diff output
- For simple stubs, hand-write a struct that implements the interface. Use a mocking framework only when you need call recording, argument matchers, or expectation ordering.
- Always run tests with `-race` in CI: `go test -race ./...` — the race detector finds data races missed by normal tests. Has runtime overhead; don't use in production builds
- Separate unit/integration/e2e tests: use `testing.Short()` with `go test -short` for fast unit tests, build tags (`//go:build integration`) for integration tests, or environment variables for selective execution
- Never use `time.Sleep` to wait for goroutines/events in tests — use channels or sync primitives for synchronization. For eventual consistency, use retry loops with timeout
- Use `httptest.NewRecorder()`/`httptest.NewServer()` for HTTP handler tests. Use `iotest.ErrReader`/`iotest.TimeoutReader` to test error handling paths
- Run tests in parallel with `t.Parallel()` + `go test -parallel=N`. Randomize order to catch initialization dependencies: `go test -shuffle=on`
- In benchmarks, use `b.Loop()` (Go 1.24+) instead of `for i := 0; i < b.N; i++` — it automatically prevents dead code elimination and handles iteration counting:
  ```go
  // ✅ Go 1.24+ — clean, no workarounds needed
  func BenchmarkFoo(b *testing.B) {
      for b.Loop() {
          Foo()
      }
  }

  // Pre-1.24 — must manually prevent dead code elimination
  var sink int
  func BenchmarkFoo(b *testing.B) {
      for i := 0; i < b.N; i++ {
          sink = Foo()
      }
  }
  ```
- Use `b.ResetTimer()` after expensive setup to exclude setup cost; use `b.StopTimer()`/`b.StartTimer()` around per-iteration setup/teardown
- Use `b.ReportAllocs()` to include allocation counts in benchmark output — helps track allocation regressions
- Use native fuzzing for inputs that are parsed, decoded, or deserialized:
  ```go
  func FuzzParseJSON(f *testing.F) {
      f.Add([]byte(`{}`))
      f.Fuzz(func(t *testing.T, data []byte) { Parse(data) })
  }
  ```
- Run fuzz tests with `go test -fuzz=FuzzParseJSON`. Crash inputs land in `testdata/fuzz/` and serve as regression tests.
- Race detector limitations: has ~5-10x runtime overhead, only detects races on code paths actually executed (not static analysis), and may miss races in infrequently-run branches — maximize code coverage to improve detection

---

# Code Structure

## Code Organization

- Use standard project layout: `cmd/` for executables, `internal/` for private packages, `pkg/` only if you explicitly want to export library code
- `internal/` packages cannot be imported from outside the parent module — use this for implementation details
- One package per directory; package name matches directory name
- Split packages when they grow beyond a single responsibility — signs: unrelated types in the same package, circular dependencies, the package name becomes vague
- File naming: `snake_case.go`, group related types/functions in the same file. Use `_test.go` suffix for test files
- Keep `main` packages thin — parse flags, wire dependencies, call into library code

## Dependencies

- Minimize dependencies — every dependency is a liability (security, maintenance, build time)
- Prefer standard library solutions over third-party when equivalent
- Use `go mod tidy` to remove unused dependencies
- Pin major versions; allow minor/patch updates: `require example.com/foo v1.2.3`
- Vendor dependencies (`go mod vendor`) for reproducible builds in CI or air-gapped environments
- Evaluate dependencies before adopting: maintenance activity, license, transitive dependency count
- Follow semantic versioning: bump major for breaking changes, minor for new features, patch for bug fixes. Major version v2+ requires a `/v2` suffix in the module path
- Use `retract` directive in `go.mod` to mark accidentally published versions; use `Deprecated:` comment in package doc for deprecated modules
- Use the `replace` directive only for local development (forked dependencies, multi-module repos) — never publish a module that relies on `replace`
- Use workspaces (`go.work`, Go 1.18+) for developing multiple modules together — avoids `replace` directives for local cross-module development

## Build Tags

- 🔧 Use `//go:build` directive (Go 1.17+) for conditional compilation, not the legacy `// +build` syntax (`go vet`)
- Common uses: platform-specific code (`//go:build linux`), integration tests (`//go:build integration`), excluding files (`//go:build ignore`)
- Place `//go:build` on the line before `package` with a blank line between

---

# Optimization

## Memory Management

- Variables escape to the heap when a pointer escapes function scope (returned, stored in a closure), size is unknown at compile time, or the value is too large.
- Reduce escapes: return values not pointers; avoid closures that capture pointers.
- Use `go build -gcflags='-m -m'` to see escape analysis and inlining decisions
- Reduce allocations: reuse buffers, pre-allocate slices, avoid unnecessary pointer indirection, prefer value types for small structs
- Pre-allocate when size is known: `make([]T, 0, expectedSize)` for slices, `make(map[K]V, expectedSize)` for maps.
- Background: `append` grows roughly 2x for small slices and asymptotically approaches 1.25x for larger slices (transition near 256 elements). Pre-allocation avoids the reallocation chain entirely.
- Use `sync.Pool` to reuse frequently allocated objects
- GC tuning: `GOGC` controls GC frequency (default 100 = GC when heap doubles). `GOMEMLIMIT` (Go 1.19+) sets a soft memory limit. Tune for latency vs throughput based on profiling

## Performance

- Prefer `strconv.Itoa` over `fmt.Sprintf("%d", n)` for int-to-string
- Use `strings.Builder` for string concatenation in loops, not `+`
- Inlining: the compiler auto-inlines small leaf functions — the budget/heuristic is compiler-version-specific. Use `//go:noinline` to prevent inlining; use `go build -gcflags='-m'` or profiling to verify inlining decisions in hot paths
- Struct field ordering affects size due to padding — order fields largest to smallest to minimize waste
- False sharing: goroutines modifying separate fields on the same cache line (64 bytes) causes performance degradation. Pad hot fields if profiling shows contention: `type Counter struct { value uint64; _ [56]byte }` pads to a full 64-byte cache line
- Use `pprof` for CPU and memory profiling: `import _ "net/http/pprof"` for HTTP servers, or `runtime/pprof` for CLI tools. Profile before optimizing — measure, don't guess. Key profiles: `cpu`, `heap`, `goroutine`, `mutex`, `block`

### Profiling Workflow
  1. **Capture**: `go test -cpuprofile=cpu.prof -memprofile=mem.prof -bench=BenchmarkX`
  2. **Analyze**: `go tool pprof cpu.prof` → use `top10` for hotspots, `list FunctionName` for line-level detail, `web` for call graph visualization
  3. **Target**: optimize functions accounting for >10% of CPU time or allocation volume — don't optimize cold paths
  4. **Verify**: re-profile after changes; use `go test -benchmem -count=5` and `benchstat` to confirm statistically significant improvements

---

# Production Practices

## Logging

- Use `log/slog` (Go 1.21+) as the standard structured logging package — it's in stdlib, supports key-value pairs, log levels, and pluggable handlers. Prefer it over third-party loggers for new projects:
  ```go
  logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
  logger.Info("user created", "userID", id, "email", email)
  logger.Error("failed to save", "err", err, "userID", id)
  ```
- Use `slog.With()` to create child loggers with common attributes — avoids repeating context on every call:
  ```go
  reqLogger := logger.With("requestID", reqID, "userID", userID)
  reqLogger.Info("processing order")  // includes requestID and userID automatically
  ```
- Use `slog.LogValuer` interface for types that appear frequently in logs — controls how they're serialized and can redact sensitive fields
- Avoid the default `log` package in production — it lacks levels, structure, and context. Acceptable for simple CLI tools or `log.Fatal` during startup failures
- Log levels: use `Debug` for development diagnostics, `Info` for normal operations, `Warn` for recoverable issues, `Error` for failures requiring attention
- Never log sensitive data — PII, credentials, tokens, full request bodies with auth headers
- Pass `*slog.Logger` via dependency injection (constructor parameter or struct field), not as a package global.
- Configure the default logger with `slog.SetDefault()` in `main`. Don't rely on `slog.Default()` deep in the call stack.
- Include context in log entries: request ID, user ID, operation name — enough to trace a request through the system
- Don't log and return an error — pick one. Boundary code logs and consumes; everything inside returns.

## Signal Handling

- Use `signal.Notify` with a buffered channel for graceful shutdown: `sigCh := make(chan os.Signal, 1); signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)`
- On signal, cancel the root context, drain in-flight requests, close database connections, then exit
- Always call `signal.Stop(sigCh)` when done to release the channel
- Set a shutdown deadline — don't wait forever for graceful shutdown; force exit after a timeout

## HTTP

- Defer `Close()` on `http.Response.Body` immediately after checking the request error, including 4xx/5xx responses. Checking the Close error is optional (it's a reader).
- Must `return` after `http.Error()` — it does not stop handler execution. Failing to return causes double-write panics or unexpected behavior
- Set timeouts on `http.Client` and `http.Server` — defaults have no timeout, which can leak goroutines
- Use `http.MaxBytesReader` to limit request body size and prevent resource exhaustion
- Set security headers in middleware: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security` for HTTPS
- Implement CORS explicitly — don't use `Access-Control-Allow-Origin: *` in production; whitelist specific origins
- Propagate request IDs via context for distributed tracing: extract from `X-Request-ID` header (or generate with `uuid`), store in context, include in all log entries and downstream requests.
- Use the middleware pattern for cross-cutting concerns (auth, logging, rate limiting, CORS):
  ```go
  func middleware(next http.Handler) http.Handler {
      return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
          // pre
          next.ServeHTTP(w, r)
          // post
      })
  }
  ```

## SQL

- `sql.Open` doesn't create connections — use `db.Ping()` to verify connectivity
- In production, always call `db.SetMaxOpenConns()` to bound load on the database (default is unlimited).
- Connection pool defaults: `MaxOpenConns` unlimited, `MaxIdleConns` 2, `ConnMaxLifetime` 0 (no limit), `ConnMaxIdleTime` 0 (no limit).
- Tune `MaxIdleConns`, `ConnMaxLifetime`, and `ConnMaxIdleTime` only when profiling shows contention or stale-connection errors.
- Always use prepared statements for repeated queries — prevents SQL injection and improves performance
- Handle NULL: use `sql.NullString`, `sql.NullInt64`, etc. — scanning NULL into a plain `string`/`int` fails
- Always check `Rows.Err()` after the scan loop: `for rows.Next() { ... }; if err := rows.Err(); err != nil { ... }`.
- Defer `Close()` on `sql.Rows` immediately; check `Close()` errors if not all rows were read

## File I/O

- Use `bufio.Scanner` or `bufio.Reader` for reading large files line-by-line — don't read the entire file into memory with `os.ReadFile` unless it's small
- Use `os.CreateTemp` for temporary files; always defer cleanup: `defer os.Remove(tmpFile.Name())`
- Check `Close()` errors on writers — data may not be flushed until Close.
- Use `filepath.Join` for path construction, not string concatenation — handles OS-specific separators

## JSON

- Nil slices/maps marshal to `null`; empty slices/maps marshal to `[]`/`{}`. Use `[]T{}` (or `map[K]V{}`) when you need `[]`/`{}` in JSON output.
- An explicit field shadows a promoted field of the same name during JSON marshaling — only the explicit field is serialized:
  ```go
  type Base struct { Name string }
  type Derived struct { Base; Name string } // Base.Name is silently dropped
  ```
- `time.Time` marshals to RFC 3339 by default — use custom `MarshalJSON`/`UnmarshalJSON` for other formats
- `omitempty` omits zero values, which includes `0`, `false`, and empty strings — use a pointer field (`*int`, `*bool`) to distinguish between zero and absent, or omit `omitempty` when zero is a valid value
- When unmarshaling into `any`, numbers become `float64` — use typed structs or `json.Number`

## Embedding

- Use `//go:embed` (Go 1.16+) to embed static files into the binary at compile time — no external file dependencies at runtime
- Embed into `string` for single text files, `[]byte` for single binary files, `embed.FS` for directories or multiple files
- `//go:embed` must be a package-level `var` declaration, not inside a function
- Embed patterns are relative to the source file's directory; cannot use `..` to escape the module
- Use `embed.FS` with `http.FileServer` for serving static web assets: `http.Handle("/static/", http.FileServer(http.FS(staticFS)))`
- Common uses: HTML templates, migration SQL files, static web assets, default configuration files

## Security

- 🔧 Use `crypto/rand` for security-sensitive random values (tokens, keys, nonces) — never `math/rand`, which is deterministic and predictable (`gosec: G404`)
- Use `subtle.ConstantTimeCompare` for comparing secrets, tokens, and hashes — standard `==` or `bytes.Equal` are vulnerable to timing attacks
- Never implement custom cryptographic algorithms — use standard library `crypto/*` packages or well-vetted libraries (`golang.org/x/crypto`)
- Hash passwords with `bcrypt` (`golang.org/x/crypto/bcrypt`) or `argon2` — never SHA-256, MD5, or plain hashing
- 🔧 Sanitize and validate all external input — URL parameters, headers, request bodies, file paths. Use `filepath.Clean` and reject path traversal (`..`) (`gosec: G304`)
- Use `html/template` (not `text/template`) for HTML output — it auto-escapes to prevent XSS

## CGO

- Minimize cgo usage — each cgo call has significant overhead (~100-200ns) due to goroutine stack switching and scheduler coordination
- Never pass Go pointers to C that contain Go pointers — violates cgo pointer passing rules and causes runtime panics:
  ```go
  // ❌ Illegal — Go struct contains a Go pointer (*[]byte)
  type Wrapper struct { data *[]byte }
  C.process(unsafe.Pointer(&wrapper))

  // ✅ Legal — Go pointer to flat data (no nested Go pointers)
  var val C.int = 42
  C.process(unsafe.Pointer(&val))
  ```
- C memory allocated with `C.malloc` must be freed with `C.free` — Go's GC does not track C allocations
- cgo breaks cross-compilation — `CGO_ENABLED=0` disables cgo for pure Go builds. Prefer pure Go alternatives when available (e.g., `modernc.org/sqlite` over `mattn/go-sqlite3`)
- Pin goroutines to OS threads with `runtime.LockOSThread()` when cgo code uses thread-local storage
