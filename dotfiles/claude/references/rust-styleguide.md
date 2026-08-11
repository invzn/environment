# Rust Style Guide

All Rust agents must follow these conventions.

This guide assumes Edition 2024 (Rust 1.85+). Version-specific behavior is noted where relevant.

Sources: [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/), Effective Rust (David Drysdale), Rust for Rustaceans (Jon Gjengset), [Rust Design Patterns](https://rust-unofficial.github.io/patterns/), [Rustonomicon](https://doc.rust-lang.org/nomicon/), std and [Tokio](https://docs.rs/tokio) API docs. This guide is authoritative; when it conflicts with the source guides, follow this guide.

**Crate policy:** This guide is deliberately crate-neutral. It endorses only `std` and `tokio` (for async), plus dev-dependencies `criterion` (benchmarks) and `proptest` (property tests) — dev-dependencies never ship in the binary. Error handling and serialization idioms are taught in terms of std traits, not crates. std has no logging facility: in binaries with no existing logging dependency, use `eprintln!` for diagnostics and do not introduce a logging crate unasked. When a codebase already uses `thiserror`, `anyhow`, `serde`, `tracing`, etc., match the existing codebase per Agent Conduct — do not rip them out or hand-roll replacements.

## Agent Conduct

These rules govern how a Rust agent applies the rest of this guide. They take precedence over any specific style rule below.

- Stay within the requested scope. Do not refactor, rename, add validation, add tests, add comments, or extract helpers beyond what the task explicitly asked for. A bug fix changes only what's needed to fix the bug. If you notice unrelated issues, mention them in your response — do not fix them silently.
- Match the existing codebase before applying this guide. If surrounding code uses an older idiom (pre-1.75 `async-trait` crate, `lazy_static`, `once_cell`, manual error enums where the codebase elsewhere uses `thiserror`), match the existing style within the file/crate and call out the divergence in your response. Do not silently modernize unrelated code.
- Apply rules at the boundaries this guide names. A rule about public APIs applies to `pub` items, not to private helpers. Do not extrapolate a rule to adjacent constructs because they "feel similar."
- The 🔧 marker means a lint exists for the rule — it does not relieve you of following the rule. Write code that already conforms; do not rely on CI to fix your output. Lints marked *(pedantic)*, *(nursery)*, or *(restriction)* are not on by default; the rule still applies.
- When two rules conflict on a specific case, prefer the rule that is more local (function-level over crate-level), more specific (named construct over general principle), and explicitly marked as overriding.
- Prefer `#[expect(...)]` (1.81+) over `#[allow(...)]` to suppress a lint — it warns when the suppression stops being necessary, so it cannot go stale. Either way, never suppress a lint without a comment justifying it.

## Recommended Toolchain

- `cargo fmt` — formatting; use rustfmt defaults, do not hand-format
- `cargo clippy -- -D warnings` — default lint groups (`correctness`, `suspicious`, `style`, `complexity`, `perf`) treated as errors
- Selected `pedantic`/`restriction` lints opted in per-crate where this guide names them (in `Cargo.toml` under `[lints.clippy]`)
- `cargo miri test` — for any crate containing `unsafe` code
- `cargo audit` / `cargo deny` — dependency vulnerability and license checks in CI

Rules that can be lint-enforced are marked with 🔧 below, with the lint name. Unqualified names are clippy lints; `rustc:` prefixes compiler lints.

## Version Notes

For matching older codebases (check `rust-version` in Cargo.toml):
- 1.63: `std::thread::scope` (borrowing spawned threads), `Mutex::new` is const
- 1.65: `let`-`else`, generic associated types (GATs)
- 1.70: `OnceCell` / `OnceLock`
- 1.75: `async fn` and return-position `impl Trait` in traits
- 1.77: C-string literals `c"..."`
- 1.80: `LazyCell` / `LazyLock` (replaces `lazy_static`/`once_cell` crates)
- 1.82: `&raw const` / `&raw mut` pointer syntax
- 1.85: **Edition 2024** — RPIT captures all in-scope lifetimes by default, `unsafe_op_in_unsafe_fn` warns by default, `unsafe extern` blocks, `unsafe` attributes, `env::set_var`/`remove_var` become `unsafe`, `Future`/`IntoFuture` in prelude
- 1.88: `let` chains (`if let Some(x) = a && x > 0`) — Edition 2024 only

---

# Foundations

## Naming

- 🔧 `snake_case` for functions, methods, variables, modules; `UpperCamelCase` for types, traits, enum variants; `SCREAMING_SNAKE_CASE` for constants and statics (`rustc: non_camel_case_types`, `rustc: non_snake_case`, `rustc: non_upper_case_globals`)
- Acronyms in `UpperCamelCase` names: only the first letter capitalized — `HttpServer`, `UrlPath`, `Uuid`. Never `HTTPServer` (opposite of Go).
- Conversion method prefixes (API Guidelines C-CONV): `as_` — cheap borrowed→borrowed view (`as_str`); `to_` — expensive owned copy or repr change (`to_string`, `to_vec`); `into_` — consuming ownership transfer (`into_bytes`, `into_inner`)
- Getters: no `get_` prefix — `user.name()`, not `user.get_name()`. Exception: `get` when there is a single obvious thing to get (`Cell::get`), including `get`/`get_mut` on container types taking a key/index and returning `Option`.
- Iterator methods: `iter()` → `&T`, `iter_mut()` → `&mut T`, `into_iter()` → `T`; a method returning an iterator names the iterator type after itself (C-ITER-TY)
- Predicates: `is_`/`has_` prefix returning `bool`
- 🔧 Constructors: `new` for the primary constructor (no arguments or the obvious ones); `with_x`/`from_x` for alternates; implement `Default` when a no-argument `new` exists (`new_without_default`)
- 🔧 Don't stutter with the module path: `process::spawn`, not `process::spawn_process` — items are referenced through their module (`module_name_repetitions`, *restriction*)
- Type parameters: single uppercase letters — `T` general, `K`/`V` key/value, `E` error; use descriptive names (`Backend`, `Codec`) when several parameters coexist
- Lifetimes: short (`'a`, `'b`) by default; descriptive (`'src`, `'conn`) when multiple lifetimes interact
- Crate names: `kebab-case` on crates.io, referenced as `snake_case` in code; avoid `rust-`/`-rs` prefixes/suffixes

## Imports and `use`

- Group `use` statements: `std`/`core`/`alloc`, then external crates, then `crate`/`self`/`super` — blank line between groups (rustfmt `group_imports` can enforce; it is unstable, so maintain groups manually)
- Import types, traits, and enums directly (`use std::collections::HashMap`); call functions through their parent module (`fmt::format`, `mem::swap`) — the module name gives call sites context
- 🔧 No glob imports except a crate's intentional `prelude` and `use super::*` in test modules (`wildcard_imports`, *pedantic*)
- 🔧 Import enum variants locally inside a `match`-heavy function if it helps readability (`use Direction::*;` scoped to the function); never at module scope (`enum_glob_use`, *pedantic*)
- Use `pub use` at the crate root to re-export the public API from deep module paths — callers should write `mycrate::Client`, not `mycrate::net::client::Client`
- Traits must be in scope for their methods to resolve; when a trait is imported only for its methods, `use std::io::Write as _;` documents that intent

## Error Handling

- `Result<T, E>` for recoverable errors; `panic!` only for bugs (violated invariants, impossible states). A library that panics on bad input is broken — return `Err`.
- Propagate with `?`. Do not `match` on a `Result` just to return the error unchanged.
- 🔧 Never `unwrap()`/`expect()` in library code, with one exception: when an invariant makes failure impossible, `expect` is allowed — with a message stating *why it cannot fail*, in the "should" style: `.expect("regex is validated at compile time")`, not `.expect("failed to compile regex")` (`unwrap_used`, `expect_used`, *restriction*). In binaries, `expect` is also acceptable at startup (config loading, arg parsing) where dying with a message is the correct behavior.
- Custom error types, crate-neutral pattern — an enum per fallible subsystem:
  ```rust
  #[derive(Debug)]
  #[non_exhaustive]
  pub enum ConfigError {
      Io(std::io::Error),
      Parse { line: usize, msg: String },
      MissingKey(String),
  }

  impl std::fmt::Display for ConfigError {
      fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
          match self {
              Self::Io(e) => write!(f, "reading config: {e}"),
              Self::Parse { line, msg } => write!(f, "parse error at line {line}: {msg}"),
              Self::MissingKey(k) => write!(f, "missing required key `{k}`"),
          }
      }
  }

  impl std::error::Error for ConfigError {
      fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
          match self {
              Self::Io(e) => Some(e),
              _ => None,
          }
      }
  }

  impl From<std::io::Error> for ConfigError {
      fn from(e: std::io::Error) -> Self { Self::Io(e) }
  }
  ```
- Implement `std::error::Error` with `source()` returning the underlying cause — this is the equivalent of Go's error wrapping; never flatten a cause into a `String` if callers might need it
- Implement `From<UnderlyingError>` so `?` converts automatically; do not write `.map_err(ConfigError::Io)` at every call site
- `#[non_exhaustive]` on public error enums — lets you add variants without a semver-major bump
- Error messages: lowercase, no trailing punctuation, state what was being attempted (`"reading config {path}"`), because messages compose into chains
- `Box<dyn std::error::Error + Send + Sync>` (or a type alias for it) is acceptable as the error type in binaries and prototypes; libraries define concrete error types
- Libraries with one dominant error type define `pub type Result<T> = std::result::Result<T, Error>;` at the crate root, mirroring `std::io::Result`
- Choosing an error type:

  | Scenario | Error type |
  |----------|-----------|
  | Library, callers branch on failure modes | Public `#[non_exhaustive]` enum with `source()` |
  | Library, one opaque failure mode | Struct wrapping the cause; expose it via `source()` |
  | Binary or prototype | `Box<dyn Error + Send + Sync>` (or an alias for it) |
  | Translating between subsystems | `From` impl converting one error enum into the other |
- Don't log and return an error — pick one. The boundary (main, request handler, task entry point) logs and consumes; everything inside returns.
  ```rust
  // ❌ logs AND returns — the error gets reported twice up the stack
  if let Err(e) = store.save(&user) {
      eprintln!("failed to save user: {e}");
      return Err(e.into());
  }

  // ✅ return the error — `?` converts via the From impl; the boundary decides how to report
  store.save(&user)?;
  ```
- Panic policy: `unreachable!()` for logically impossible branches, `debug_assert!` for internal invariants checked in debug only, `assert!` for cheap invariants worth keeping in release. Document every reachable panic in a `# Panics` doc section.
- Never let a panic cross an FFI boundary — panicking out of an `extern "C"` fn aborts. Use `std::panic::catch_unwind` at FFI and thread boundaries only; never for control flow.
- 🔧 Prefer `.get(i)` returning `Option` over indexing `[i]` in library code where out-of-bounds is reachable from caller input (`indexing_slicing`, *restriction*)

## Numeric Types

- 🔧 Integer arithmetic: debug builds panic on overflow, release builds wrap silently. For arithmetic on untrusted or unbounded input, choose explicitly: `checked_add`, `saturating_add`, or `wrapping_add` (`arithmetic_side_effects`, *restriction*)
- 🔧 `as` casts truncate and change sign silently — prefer `From`/`TryFrom` for integer conversions (`cast_possible_truncation`, `cast_sign_loss`, *pedantic*)
- 🔧 Never compare floats with `==`; use an epsilon (`float_cmp`, *pedantic*). For money, use integer minor units — never floating point.

## Functions

- 🔧 Keep functions under ~60 lines; split when branching accretes — separate validation, core logic, and formatting (`too_many_lines`, *pedantic*, fires at 100)
- 🔧 Keep cognitive complexity low — deep nesting and interleaved conditions are the signal to extract (`cognitive_complexity`, *nursery*)
- Return early — handle errors and edge cases first with `?` and `let`-`else` guard clauses; keep the happy path left-aligned

## Documentation

- 🔧 `///` doc comments on all public items; first line is a one-sentence summary in the third person ("Returns...", "Creates...") (`rustc: missing_docs`, opt-in via `#![warn(missing_docs)]` on libraries)
- 🔧 Standard sections in order, when applicable: `# Examples`, `# Errors` (when returning `Result`), `# Panics` (any reachable panic), `# Safety` (unsafe fns) (`missing_errors_doc`, `missing_panics_doc`, *pedantic*; `missing_safety_doc`)
- Doc examples are compiled and run as tests — keep them minimal, use `?` in examples via the hidden `# fn main() -> Result<...>` pattern, hide setup lines with `#`
- Use intra-doc links: `` [`Client`] ``, `` [`Self::send`] `` — they're checked at doc build
- Mark superseded public items with `#[deprecated(since = "1.2.0", note = "use new_fn instead")]` — downstream callers get a compiler warning. `since` must be a real semver version: 🔧 `deprecated_semver` (deny-by-default) rejects placeholders like `x.y.z`.
- Crate-level docs in `lib.rs` with `//!` — what the crate does, a quickstart example
- Avoid comments that restate the code; comment *why*, not *what*

---

# Ownership and API Design

## Borrowing in APIs

- 🔧 Parameters: accept `&str` not `&String`, `&[T]` not `&Vec<T>`, `&Path` not `&PathBuf` (`ptr_arg`)
- 🔧 Take ownership (`String`, `Vec<T>`) when the function stores the value; borrow when it only reads. Don't take `String` and clone-happy callers will follow (`needless_pass_by_value`, *pedantic*)
  ```rust
  // ❌ takes ownership it doesn't need — callers clone to keep their value
  fn contains_user(&self, name: String) -> bool { self.users.contains_key(&name) }
  let found = db.contains_user(name.clone());

  // ✅ borrow for reads; take ownership only when storing
  fn contains_user(&self, name: &str) -> bool { self.users.contains_key(name) }
  let found = db.contains_user(&name);
  ```
- `impl AsRef<str>` / `impl Into<String>` parameters are for ergonomic, widely-called public APIs only — they cost compile time and API clarity; internal functions take `&str`/`String` directly
- Return `Cow<'_, str>` when a function sometimes borrows and sometimes allocates; don't allocate unconditionally just to unify return types
- Returning references ties the borrow to `&self` — fine for getters; for iteration prefer returning `impl Iterator<Item = &T> + '_` over collecting into a `Vec`
- 🔧 Clone is not a sin: a `clone()` of small data in cold code is better than lifetime gymnastics. But a `clone()` added *only* to satisfy the borrow checker deserves a second look — restructuring (split borrows, move the read before the write, take ownership) usually wins (`redundant_clone`, *nursery*)
- Prefer splitting a struct into smaller structs over fighting partial-borrow errors — the borrow checker works per-field through direct field access but not through methods
- Don't store references in structs by default — start with owned fields; introduce lifetime parameters only for measured hot paths or genuinely borrowed views (parsers over an input buffer)

## Smart Pointers and Interior Mutability

- `Box<T>`: heap allocation for recursive types, large values, or `dyn Trait` — not a general "make it work" tool
- `Rc<T>` single-threaded shared ownership; `Arc<T>` thread-safe shared ownership. Reach for them only when ownership genuinely has multiple owners — shared *access* is what borrows are for.
- Interior mutability decision table:

  | Need | Type |
  |------|------|
  | Mutate a `Copy` value behind `&self`, single-threaded | `Cell<T>` |
  | Mutate non-`Copy` behind `&self`, single-threaded | `RefCell<T>` |
  | Mutate behind `&self`, multi-threaded | `Mutex<T>` / `RwLock<T>` |
  | Counter/flag, multi-threaded | `AtomicUsize` / `AtomicBool` |
  | One-time lazy init | `OnceLock<T>` / `LazyLock<T>` |
- `Rc<RefCell<T>>` appearing in a design is a smell — usually the ownership story hasn't been thought through; consider handles/indices into a central store, or restructure. Legitimate uses exist (graph structures with genuinely shared mutable nodes, single-threaded interpreter environments, GUI callback registries) — reach them by elimination, not by default.
- `RefCell` panics on double-borrow at runtime — you are trading compile-time checking for a runtime crash; keep borrow scopes minimal and never hold a borrow across a callback
- Atomics take an explicit `Ordering`: `Relaxed` for standalone counters and flags no other data depends on; `Release` on the store / `Acquire` on the load when the atomic publishes writes to other memory; `SeqCst` only when reasoning genuinely requires a single global order (rare — comment why). If choosing an ordering takes real thought, use a `Mutex` — never hand-roll lock-free data structures.
- Global state: `static X: LazyLock<T>` (1.80+) for lazy statics; `OnceLock` when initialization needs runtime input. Avoid mutable globals; pass dependencies explicitly.

## Drop and RAII

- 🔧 `let _ = expr` drops the value immediately; `let _guard = expr` holds it to end of scope. Never bind a `MutexGuard` or other RAII guard to `_` (`let_underscore_lock`, deny-by-default, catches the lock case). To end a critical section early, call `drop(guard)` — explicit and searchable.
- A temporary created in a `match`/`if let` scrutinee lives until the end of the whole expression: `match map.lock().unwrap().get(&k) { ... }` holds the lock through every arm, so re-locking inside an arm deadlocks — bind the guard to a local first
- `Drop::drop` must never panic — a panic during unwind aborts the process. Do fallible cleanup in an explicit `close(self) -> Result<...>`; `Drop` is the silent best-effort fallback.
- You cannot move fields out of a type implementing `Drop` (E0509) — store such fields as `Option<T>` and `.take()` them, or use `mem::take`/`mem::replace`
- Drop order: locals drop in reverse declaration order, struct fields in declaration order — when a struct holds a guard and the resource it guards, declare the guard field first so it drops first

## API Design Patterns

- Builder pattern for constructors with more than ~3 optional parameters; consuming builders (`self -> Self`) chain ergonomically:
  ```rust
  let server = Server::builder()
      .timeout(Duration::from_secs(10))
      .max_connections(100)
      .build()?;
  ```
  `build()` returns `Result` if validation can fail; the builder holds `Option`s/defaults internally
- Newtype pattern for domain values: `struct UserId(u64);` — prevents argument transposition, carries invariants, costs nothing at runtime. Derive what the type semantically supports (`Clone, Copy, Debug, PartialEq, Eq, Hash`), no more.
- Typestate for protocol-like APIs where operations are only valid in certain states (`Request<Building>` → `Request<Ready>`) — use sparingly; it multiplies types
- 🔧 Derive `Debug` on public types by default (`rustc: missing_debug_implementations`, opt-in) — **except** types holding secrets, credentials, or tokens: derived `Debug` prints them verbatim into logs and panic messages, so implement `Debug` manually with redaction (`write!(f, "Credentials {{ user: {}, password: [REDACTED] }}", self.user)`). `Clone`, `PartialEq` when semantically valid; `Copy` only for small (≤ ~2 words) value types whose copies are semantically free.
- 🔧 `Eq`, `Hash`, and `Ord` are a contract, not a menu: `a == b` must imply equal hashes, and `Ord` must agree with `PartialEq`/`PartialOrd`. Derive them together or implement them together over the same fields — never mix a manual impl of one with derives of the others (`derived_hash_with_manual_eq`, deny-by-default, catches the Hash/Eq case). To sort by one key without redefining equality, use `sort_by_key` at the call site.
- 🔧 `#[must_use]` on functions whose return value is the entire point (builders, pure computations) and on guard-like types (`must_use_candidate`, *pedantic*)
- `#[non_exhaustive]` on public enums and structs that will grow — on enums it forces downstream `match` to include `_`; on structs it blocks downstream literal construction and forces `..` in destructuring patterns
- Do not implement `Deref` to emulate inheritance — `Deref` is for smart pointers only
- Implement std traits rather than inventing methods: `Display` (never implement `ToString` directly — a blanket impl provides it for every `Display` type), `FromStr`, `From`/`TryFrom` for conversions, `IntoIterator` for collection-likes, `Default` for zero-config construction
- `Display`/`FromStr` are a round-trip pair: `s.parse::<T>()` must accept everything `t.to_string()` produces — a natural property test. When a codebase serializes with serde, mirror its existing attribute conventions (`rename_all`, `deny_unknown_fields`) instead of inventing per-type styles.
- Implement `From`, bound on `Into`: provide `impl From<A> for B`; generic functions take `impl Into<B>`
- Sealed trait pattern when downstream impls would break your evolution:
  ```rust
  mod private { pub trait Sealed {} }
  pub trait Backend: private::Sealed { /* ... */ }
  ```

---

# Type System

## Traits, Generics, and Dispatch

- Default to generics (static dispatch): `fn process<B: Backend>(b: &B)` or `fn process(b: &impl Backend)`. Use `dyn Trait` for heterogeneous collections (`Vec<Box<dyn Handler>>`), plugin registries, or to cut compile time/binary size on cold paths. Unlike Go's "accept interfaces" idiom, generic parameters are the Rust default — `dyn` is for heterogeneous storage, not a reflex.
- `dyn Trait` costs an indirect call per invocation (no inlining across the vtable) and, when boxed, a heap allocation — acceptable on cold paths, a real cost in per-item hot loops
- `impl Trait` in argument position is fine for simple bounds; switch to named generics when the caller might need turbofish or the type appears twice
- Return-position `impl Trait` (RPIT) for returning closures and iterators; note Edition 2024 captures all in-scope lifetimes by default (use `+ use<>` syntax to opt out)
- Accept the loosest closure bound that works: `FnOnce` if called at most once, `FnMut` if called repeatedly, `Fn` only if called through a shared reference (e.g. concurrently) — over-demanding `Fn` forces callers to clone captured state. Take closures as generics (`impl FnOnce(...)`); `Box<dyn Fn...>` is for storing callbacks in structs, not for parameters.
- `where` clauses when bounds don't fit inline; put the bound where it's needed (on the method, not the struct, unless the struct's invariants require it)
- Dyn compatibility (object safety): no generic methods, no methods mentioning `Self` in their signature (e.g. returning `Self`), no associated consts. A method can opt out of the vtable with `where Self: Sized`, keeping the rest of the trait dyn-compatible; by-value `self` methods don't break dyn compatibility but cannot be called through `dyn`. Design traits you intend to box accordingly; split a trait into a dyn-compatible core plus generic extension methods if needed
- `async fn` in traits (1.75+) works for generics but such traits are not dyn-compatible — if you need `Box<dyn Service>`, desugar to `fn(&self) -> Pin<Box<dyn Future<Output = T> + Send + '_>>` manually or keep the trait generic-only
- Avoid trait hierarchies more than two levels deep; prefer composition of small traits
- Blanket impls (`impl<T: Foo> Bar for T`) are powerful and irrevocable in semver terms — add one only with a doc comment on the impl stating its intended scope and why a blanket (rather than per-type) impl is warranted
- Orphan rule (coherence): a trait impl is legal only if your crate defines the trait or the type. To implement a foreign trait for a foreign type, wrap the type in a newtype (see API Design Patterns) — that is the standard workaround.
- Trait objects carry an implicit lifetime bound — `Box<dyn Trait>` means `Box<dyn Trait + 'static>` and cannot hold borrowed data. When a trait object borrows, name the bound explicitly: `Box<dyn Handler + 'a>` (or `+ '_`).

## Lifetimes

- Let elision work — write explicit lifetimes only when the compiler demands or when relations between multiple references matter
- `T: 'static` as a bound means "owns all its data" (no borrowed references) — it does not mean the value lives forever; `String` is `'static` in this sense
- A method taking `&'a mut self` and returning `&'a T` locks the whole struct for the borrow's life — prefer returning owned data or restructuring when this bites callers

## Pattern Matching

- 🔧 `match` on enums defined in the *same crate* must be exhaustive without `_` — a wildcard arm silently swallows future variants; list variants explicitly so adding one breaks compilation (`wildcard_enum_match_arm`, *restriction*)
- `_` catchalls are fine on `#[non_exhaustive]` enums from any other crate (required — the attribute forces `_` even in sibling crates of your own workspace) and on truly don't-care integer/char matches
- 🔧 `let`-`else` for extract-or-early-return: `let Some(user) = find(id) else { return Err(...) };` (`manual_let_else`, *pedantic*)
- `if let` for a single variant when the other cases genuinely need nothing; `matches!(x, Pattern)` for boolean checks
- Prefer combinators when they read linearly — `opt.map(f).unwrap_or_default()`, `result.ok_or(Error::Missing)?` — and `match` when logic branches or nests; never chain more than ~3 `Option`/`Result` combinators (this limit does not apply to iterator adapter chains, which stay readable much longer)
- Destructure structs in `match`/`let` to bind several fields at once; use `..` to ignore the rest explicitly
- `@` bindings capture while testing: `n @ 1..=5 => ...`
- Model states as data-carrying enums, not flag fields: ❌ `struct Conn { connected: bool, addr: Option<Addr> }` → ✅ `enum Conn { Disconnected, Connected(Addr) }` — make invalid states unrepresentable

---

# Collections and Iterators

- 🔧 Prefer iterator chains over index loops (`needless_range_loop`); prefer `for` loops over `.for_each()` except at the end of long chains
- 🔧 In release builds, statically dispatched iterator chains compile to the same code as hand-written loops. That does not hold in debug builds or across `Box<dyn Iterator>`/`Box<dyn Fn>` boundaries, where dynamic dispatch defeats inlining. An intermediate `.collect::<Vec<_>>()` mid-chain forces an allocation and defeats laziness — keep the chain lazy until the final consumer (`needless_collect`, *nursery*)
- Collect a `Vec<Result<T, E>>` into `Result<Vec<T>, E>` directly: `items.iter().map(parse).collect::<Result<Vec<_>, _>>()?` — stops at first error
- `iter()` borrows, `into_iter()` consumes, `iter_mut()` mutates in place — a `for x in collection` loop calls `into_iter()` and consumes; loop over `&collection` to borrow
- 🔧 Use the entry API for insert-or-update: `*map.entry(key).or_insert(0) += 1` — one lookup, not two (`map_entry`)
- 🔧 `Vec::with_capacity(n)` / `HashMap::with_capacity(n)` when size is known — but never with an `n` read from untrusted input (see Security); `String` building in loops: `push_str`/`write!`, never `s = s + part` or repeated `format!` (`string_add`, *restriction*; `format_collect`, *pedantic*)
- In-place: `retain` over filter-and-reassign, `drain` to move elements out, `swap_remove` when order doesn't matter (O(1))
- 🔧 `sort_unstable` by default — faster, no allocation; `sort` only when equal-element order matters (`stable_sort_primitive`, *pedantic*)
- `HashMap` iteration order is arbitrary and varies per process — `BTreeMap` when deterministic order matters; `VecDeque` for FIFO queues
- Strings: `len()` is bytes, not chars; `chars()` yields Unicode scalars, not grapheme clusters — slicing at a non-boundary byte index panics. Use `char_indices()`, `get(a..b)` for fallible slicing.
- `&str` for borrowed text, `String` for owned, `&[u8]`/`Vec<u8>` for bytes that may not be UTF-8 — convert with `from_utf8` (checked), never `from_utf8_unchecked` outside proven-safe decoding paths
- Paths are not strings: display with `path.display()`, never `to_str().unwrap()` (panics on non-UTF-8 paths); `to_string_lossy()` only for human-facing text; keep `Path`/`OsStr` end-to-end when the value goes back to the filesystem

---

# IO

- Wrap `File` in `BufReader`/`BufWriter` for anything beyond a one-shot `fs::read_to_string`/`fs::write` — unbuffered read/write loops pay a syscall per call
- `BufWriter`'s implicit flush on drop ignores errors — call `flush()?` explicitly before the writer goes out of scope
- Bulk terminal output: lock once (`let mut out = io::stdout().lock()`) and `writeln!` to it — `println!` re-locks per call. Data goes to stdout; diagnostics and progress go to stderr, so output stays pipeable.
- Prefer returning from `main` (or `std::process::ExitCode`) over `std::process::exit`, which skips destructors and unflushed buffers
- `main() -> Result<_, E>` reports the error via `Debug`, not `Display` — for user-facing binaries, catch the error in `main` and print its `Display` chain (walk `source()`) to stderr yourself

---

# Concurrency and Async

## Send/Sync and Threads

- `Send` (movable across threads) and `Sync` (shareable by reference) are auto-derived from fields; `Rc`, `RefCell`, and raw pointers break them. Design types intended for concurrent use out of `Send + Sync` parts.
- Data races are compile errors in safe Rust — but deadlocks, race conditions on external state, and channel misuse are not; the type system does not absolve you of concurrency design
- `std::thread::scope` (1.63+) to spawn threads that borrow from the parent stack; plain `thread::spawn` requires `'static` data
- Lock discipline: keep critical sections short; never call unknown/user code while holding a lock; acquire multiple locks in one global order
- A poisoned `Mutex` (a thread panicked while holding it) — propagating the panic with `.expect("lock poisoned: holder panicked")` is standard in binaries *and* libraries (poisoning means another thread already hit a bug, an explicit exception to the library `expect` ban); libraries that must keep functioning past poisoning use `.unwrap_or_else(|p| p.into_inner())` deliberately
- Returning a guard (`MutexGuard`) from a public method leaks locking policy into the API — wrap access in methods instead

## Tokio

### Task lifecycle

- `tokio::spawn` requires `'static + Send` — clone the `Arc`s you need before the `move` block; a spawn that borrows locals won't compile, and that's the design speaking
- Never fire-and-forget: dropping a `JoinHandle` detaches the task and swallows its panics/errors. Hold handles and await them, or use `JoinSet` for dynamic groups (awaiting results as they finish — the errgroup equivalent).
- Don't spawn a task per small item in a hot loop — every `spawn` allocates a task and pays scheduler overhead; batch items into fewer tasks, or process them within one task with an iterator/stream
- `async fn` desugars to a state machine holding every local variable live across an `.await` — deeply nested unboxed async chains inflate the future's size. `Box::pin` a large future to move it to the heap once; recursive `async fn` requires it (the type would otherwise be infinitely sized).
- `Pin` exists because a started future must not move (its state machine may be self-referential). You rarely write `Pin` directly: `Box::pin` for owned futures, `tokio::pin!` to pin on the stack when a `select!` loop polls the same future across iterations. `Pin<&mut Self>` semantics only matter when implementing `Future`/`Stream` by hand — most types are `Unpin` and exempt from the ceremony.
- Don't sprinkle `#[tokio::main]` beyond `main` — libraries take a runtime as given (functions are just `async fn`); binaries own the runtime

### Cancellation and shutdown

- Cancellation safety: a future dropped at an `.await` point simply stops. In `select!`, the non-chosen branches are *dropped* — if a branch was mid-read on a buffered stream, data is lost. Only use cancellation-safe operations in `select!` arms (the tokio docs mark them); otherwise restructure with message passing.
  ```rust
  // ❌ read_line is not cancellation-safe — a tick can drop it mid-read, losing buffered data
  loop {
      buf.clear();
      tokio::select! {
          _ = interval.tick() => flush_stats(),
          Ok(n) = reader.read_line(&mut buf) => {
              if n == 0 { break; }
              process(&buf);
          }
      }
  }

  // ✅ isolate the read in its own task; the select loop consumes only complete messages
  let (tx, mut rx) = tokio::sync::mpsc::channel(16);
  let reader_task = tokio::spawn(async move {
      loop {
          let mut line = String::new();
          match reader.read_line(&mut line).await {
              Ok(0) | Err(_) => break,
              Ok(_) => { if tx.send(line).await.is_err() { break; } }
          }
      }
  });
  loop {
      tokio::select! {
          _ = interval.tick() => flush_stats(),
          maybe_line = rx.recv() => match maybe_line {
              Some(line) => process(&line),
              None => break, // reader task ended (EOF or read error)
          },
      }
  }
  reader_task.await.expect("reader task panicked"); // never fire-and-forget: surface the task's panics
  ```
- Graceful shutdown pattern: listen on `tokio::signal::ctrl_c()`, broadcast shutdown via a `watch` channel, give tasks a deadline (`tokio::time::timeout`) to drain, then abort stragglers via `JoinSet::abort_all`
- There is no async `Drop`: types owning async resources need an explicit `async fn shutdown(self)` — document that dropping without calling it leaks or blocks

### Blocking and locking

- Blocking work on the runtime starves all tasks on that worker: CPU-bound or blocking-IO work goes in `tokio::task::spawn_blocking`; async code must not call blocking std IO, `std::thread::sleep`, or busy loops without `yield_now`. The blocking pool is bounded (512 threads by default) and each call dispatches to another OS thread — batch small blocking calls rather than issuing thousands.
- 🔧 Mutex choice: `std::sync::Mutex` for short critical sections that never hold the guard across `.await` (it's faster, and a std guard held across `.await` either fails `tokio::spawn`'s `Send` bound, stalls every task on that worker thread, or deadlocks a current-thread runtime outright); `tokio::sync::Mutex` only when the guard must live across an `.await` (`await_holding_lock`, *suspicious*, catches std guards held across await)

### Channels

- Channels: `mpsc::channel(n)` bounded by default — backpressure is a feature; `unbounded_channel` needs a stated justification (as with Go's buffered channels). `oneshot` for single request/reply, `watch` for latest-value state, `broadcast` for fan-out.
- Size bounded channels from measured throughput, not folklore: too small parks senders constantly; too large defeats the backpressure signal and grows worst-case memory. Start small (tens) and raise only on evidence of sender contention.
- Prefer passing data through channels over sharing `Arc<Mutex<T>>` state between tasks, when the data has a clear producer→consumer direction (same principle as Go's "share by communicating")

## Time

- `Instant` for measuring elapsed time (monotonic); `SystemTime` for wall-clock timestamps (can go backwards); never mix them
- `Duration` for spans — API parameters take `Duration`, never bare `u64` millis
- In async code use `tokio::time::{sleep, timeout, interval}` — `std::thread::sleep` blocks the whole runtime worker

---

# Unsafe

- `unsafe` is justified for: FFI, building safety abstractions std doesn't provide (novel data structures, allocators), and profiled hot paths where a safe alternative measurably can't reach the target. It is not justified for convenience or to silence the borrow checker.
- Minimize the radius: the `unsafe` block covers only the unsafe operation; the enclosing module wraps it in a safe API whose invariants make misuse impossible. Callers of your safe API must not be able to trigger UB — if they can, the abstraction is unsound, full stop.
- 🔧 Every `unsafe` block carries a `// SAFETY:` comment stating why the invariants hold at this call site (`undocumented_unsafe_blocks`, *restriction*)
- 🔧 Every `unsafe fn` documents its contract under `# Safety` in rustdoc (`missing_safety_doc`)
- Edition 2024 warns on `unsafe_op_in_unsafe_fn` by default — write explicit `unsafe {}` blocks inside `unsafe fn` bodies, each with its own SAFETY comment
- Avoid `mem::transmute` — nearly always there's a safer tool: `to_ne_bytes`/`from_ne_bytes`, pointer `cast()`, `f32::to_bits`. Transmute is the last resort and needs a paragraph-length SAFETY comment.
- Run `cargo miri test` in CI for any crate containing `unsafe` — Miri catches UB (use-after-free, invalid aliasing, uninitialized reads) that tests pass over silently. Miri only sees executed paths and does not model most external C calls — a clean run is not a soundness proof; pair it with property tests over the unsafe-backed API.
- Common UB to design against: creating a reference (even briefly) to uninitialized memory (`MaybeUninit` + raw pointers instead), aliasing a `&mut`, dangling pointers past owner drop, invalid values (a `bool` that is 3)

## FFI

- `#[repr(C)]` on every struct crossing the boundary; plain Rust repr layout is unspecified
- `extern "C"` fns must not panic — wrap bodies in `std::panic::catch_unwind` and translate to an error code. `catch_unwind` requires the default `panic = "unwind"`: with `panic = "abort"` (see Optimization) the barrier is silently ineffective and any panic aborts the host process — never combine `panic = "abort"` with `extern "C"` entry points.
- String crossing: `CString` (owned, NUL-terminated) out, `CStr` borrowed in; never pass `&str`/`String` raw — no NUL terminator
- Memory allocated by C is freed by C; memory allocated by Rust is freed by Rust — never mix allocators across the boundary. Provide paired `create`/`destroy` externs.
- Isolate raw bindings in a `-sys`-style module/crate; the safe wrapper lives above it

---

# Macros

- Reach for macros last: function → generic function → trait → declarative macro → proc macro, in that order of escalation
- `macro_rules!` is appropriate for: repetitive trait impls over tuples/primitives, internal test-case generation, small DSL surfaces (like `vec!`). Keep patterns few and simple.
- Macros must not hide control flow that affects the caller — a macro that `return`s or `?`s invisibly makes call sites lie
- Scope: prefer `pub(crate) use` over `#[macro_export]` for internal macros; `#[macro_export]` is crate-root-public and semver-relevant
- Use `$crate::` paths inside exported macros so they resolve at any call site
- Proc macros cost a separate crate, compile time, and IDE opacity — justified for derive-style ergonomics used many times (`#[derive(Builder)]`), not for one-off code generation; document exactly what code they emit

---

# Testing

- Unit tests live in a `#[cfg(test)] mod tests` block in the same file — they may test private items; integration tests live in `tests/` and see only the public API. Choose deliberately: coverage of internals vs. contract-level tests.
- Each file directly under `tests/` compiles as its own crate — group integration tests into a few files; shared helpers go in `tests/common/mod.rs` (a `tests/common.rs` file would itself be collected as a test crate)
- Mark expensive tests `#[ignore = "reason"]`; run them explicitly with `cargo test -- --ignored`
- Doctests are the third tier: every public-API example is a compiled, running test (library targets only — `cargo test` skips doctests in binary crates) — keep them realistic
- Test names describe the scenario: `fn rejects_empty_input()`, not `fn test1()`; no `test_` prefix (the attribute already marks it)
- `assert_eq!`/`assert_ne!` over bare `assert!(a == b)` — they print both values on failure; add context args for non-obvious asserts: `assert_eq!(got, want, "case: {name}")`
- Tests return `Result`: `fn parses() -> Result<(), ParseError>` lets tests use `?` instead of unwrap ladders
- `#[should_panic(expected = "substring")]` always with `expected` — a bare `should_panic` passes on *any* panic, including the bug you're not testing
- `unwrap`/`expect` are fine in test code — a panic is a test failure. Note `unwrap_used`/`expect_used` still fire under `#[cfg(test)]` by default; crates opting into those lints set `allow-unwrap-in-tests = true` (and `allow-expect-in-tests`) in `clippy.toml`.
- Async tests: `#[tokio::test]`; use `tokio::time::pause()` + `advance()` to test timeouts without real waiting — never `sleep` your way to determinism
- Never use real sleeps to wait for concurrent work in tests — await the handle, use channels, or paused time
- Shared state across tests: tests run in parallel by default — tests touching process-globals (env vars, cwd, ports) must be isolated or serialized; prefer injecting the dependency
- Property tests (dev-dependency `proptest`) for anything that parses, decodes, or round-trips: assert invariants (`decode(encode(x)) == x`) over hand-picked cases; failing seeds persist as regression tests
- Benchmarks: `#[bench]` is nightly-only — use the `criterion` dev-dependency with `cargo bench`; benchmark real workloads, use `black_box` to defeat const-folding
- Fixtures: `include_str!`/`include_bytes!` for small embedded fixtures; a `tests/data/` directory for larger ones
- Run `cargo clippy --all-targets` so test code is linted too

---

# Security

- Path traversal: when building a filesystem path from untrusted input (upload names, URL segments), reject `Component::ParentDir` and absolute components via `Path::components()` before joining, or `canonicalize()` the parent directory and verify it `starts_with()` the intended root before joining the final component — `canonicalize()` fails on paths that don't exist yet (an upload target usually doesn't), and unlike the component check it also resolves symlinks. String checks for `".."` are insufficient.
- `HashMap`'s default hasher (randomized SipHash) is deliberately hash-flooding-resistant — never replace it with a faster non-randomized hasher for maps keyed by attacker-controlled input (headers, form fields, JSON keys)
- Never preallocate from an untrusted size field: a length prefix an attacker controls can drive a multi-GB `with_capacity` before any data arrives — clamp against a maximum or read incrementally (`Read::take`). Bound recursion depth in hand-written parsers over untrusted input for the same reason.
- Error `Display` output composes into chains that callers may log or return to clients — keep secrets, credentials, and internal paths out of error messages (and out of derived `Debug`; see API Design Patterns)
- Never derive tokens, session IDs, or nonces from `SystemTime`/`Instant` — they are predictable. std has no CSPRNG; treat secure randomness as an explicit out-of-policy dependency decision, not something to approximate with time.
- Comparing secrets with `==` short-circuits and leaks timing. std has no constant-time compare; flag the need for a vetted crate (e.g. `subtle`) explicitly rather than silently using `==`.
- `std::process::Command`: pass arguments via `.arg()`/`.args()` (no shell involved); never build a shell string from user input

---

# Project Structure

## Cargo

- 🔧 Set `edition = "2024"` and `rust-version` (MSRV) in `Cargo.toml`; CI should build against the stated MSRV (`incompatible_msrv` flags std APIs newer than the declared `rust-version`)
- Minimize dependencies — every crate is supply-chain surface, compile time, and maintenance (this guide's crate policy exists for a reason). Audit before adopting: maintenance activity, transitive tree size (`cargo tree`), license.
- Specify dependency versions as `"1.2"` (semver-compatible range); avoid `"*"` and avoid `=` pins outside reproducibility-critical binaries. Commit `Cargo.lock` for binaries; for libraries it's optional (modern guidance: committing it is fine).
- Features must be additive — enabling a feature never removes or changes API; never define mutually-exclusive features. Name them for what they add (`json`, `async`); keep `default` minimal but useful.
- Gate optional dependencies behind features: `dep:name` syntax; `#[cfg(feature = "json")]` on the modules they enable
- Workspaces for multi-crate repos: shared `[workspace.dependencies]` for version alignment, one `Cargo.lock` at the root; inherit shared fields from `[workspace.package]` with `version.workspace = true` / `edition.workspace = true` so member crates version together

## Modules and Layout

- Module files: `foo.rs` + `foo/` subdirectory — not `foo/mod.rs` (both work; pick the non-`mod.rs` style and be consistent)
- Visibility: private by default, `pub(crate)` for internals shared across modules, `pub` only for the deliberate public surface — every `pub` is a semver commitment
- Semver breaks that don't look like API edits: adding a non-`Send`/`Sync` field (`Rc`, `RefCell`) silently strips those auto traits from the containing public type; tightening a bound on an existing public item; a returned `impl Trait` no longer implementing an auto trait (a future losing `Send` breaks every downstream `tokio::spawn`). Check auto-trait fallout deliberately when editing public types in a library.
- Re-export the public API at the crate root with `pub use`; deep paths are an implementation detail
- Binary + library pattern: `main.rs` stays thin (parse args, wire config, call `lib.rs`); all logic in the library where integration tests and other binaries can reach it — mirror of Go's thin-`main` rule
- Don't mutate process env at runtime — `env::set_var`/`remove_var` are `unsafe` in Edition 2024 (they race with concurrent `getenv`); read config once at startup and pass it down. In tests, inject values instead of setting env vars.
- Multiple binaries: `src/bin/*.rs`, sharing the crate's library
- Split a module when it accretes unrelated types or its name goes vague (`utils`, `helpers`, `common` are the same dumping grounds they are in Go — name modules by what they provide)
- One concept per module; the module tree is your table of contents — a reader should locate code from names alone
- Platform-specific code (the analog of Go's build tags): gate modules with `#[cfg(unix)]` / `#[cfg(target_os = "...")]` behind one common interface — `#[cfg(unix)] mod imp; #[cfg(windows)] mod imp;` re-exported as a single API; use `cfg_attr` for conditional attributes

---

# Optimization

- Measure first: `criterion` benchmarks, `perf`/`cargo flamegraph` profiles, on `--release`. Debug builds are 10-100x slower and optimize nothing — never draw performance conclusions from them.
- The compiler reorders struct fields automatically (default `repr(Rust)`) — manual largest-to-smallest ordering is unnecessary (unlike Go); only `#[repr(C)]` layouts need hand care
- 🔧 An enum is as large as its largest variant (plus a discriminant tag, rounded to alignment — niche optimization elides the tag for types like `Option<&T>`/`Option<Box<T>>`, which stay pointer-sized) — box oversized variants: `Large(Box<BigStruct>)` (`large_enum_variant`)
- Allocation discipline in hot paths: `with_capacity`, reuse buffers (`clear()` + refill instead of new `Vec`), `write!` into an existing `String`, avoid `format!`/`to_string`/`clone` per iteration
- 🔧 Pass small `Copy` types by value (`u64`, `Instant`); references to them cost indirection for nothing (`trivially_copy_pass_by_ref`, *pedantic*)
- `Arc::clone` and drop are atomic read-modify-writes — cloning in a hot multi-core loop ping-pongs the refcount's cache line; clone once outside the loop and pass references inside
- Iterators over indexing skips bounds checks; slices' `chunks`/`windows`/`split_at` express access patterns the optimizer vectorizes well
- `#[inline]` only on tiny functions in a library's cross-crate hot path (generics are already inlined across crates); trust the compiler otherwise. For binaries, `lto = "thin"` in the release profile gets most of the benefit globally.
- Release profile tuning when binary size/speed matters: `lto`, `codegen-units = 1`, `panic = "abort"` (note: abort kills `catch_unwind` — incompatible with FFI panic barriers)
- `String`/`Vec` growth is amortized O(1) per push (current std doubles capacity — an implementation strategy, not a documented guarantee); pre-allocation only matters in measured hot loops or for very large known sizes
- Zero-copy parsing (borrowing `&str` slices from an input buffer) beats owned extraction when the input outlives the parse — this is the legitimate home of lifetime-parameterized structs
