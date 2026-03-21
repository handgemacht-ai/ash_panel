# Architecture

## Stack
- **Language:** Elixir ~> 1.17
- **Framework:** Phoenix LiveView ~> 1.0, Ash Framework ~> 3.0
- **Reactive state:** AshComputer ~> 0.2.0
- **Key deps:** Spark ~> 2.0 (DSL engine), Inflex (pluralization)
- **Testing:** ExUnit, ash_scenario (test data)

## Key Modules
- **`AshPanel`**: Library entry point and version helper
- **`AshPanel.Introspection`**: Auto-discovers resource metadata (attributes, relationships, actions) from Ash resources and builds `ResourceSchema` structs
- **`AshPanel.ComputerGenerator`**: Macro that generates AshComputer definitions (list/detail/form) from introspected schemas
- **`AshPanel.LiveView`**: `use` macro that wires up computers, event handlers, and assigns into a Phoenix LiveView
- **`AshPanel.ResourceLive`**: Higher-level `use` macro providing a complete CRUD LiveView (index/show/new/edit) with routing
- **`AshPanel.Router`**: `ash_panel_resource` macro for mounting RESTful LiveView routes
- **`AshPanel.Components.*`**: Behavior-based swappable UI components (table, filter bar, pagination)
- **`AshPanel.Computers.*`**: Standalone filter and pagination computer logic
- **`AshPanel.Views.*`**: Pre-built view components (ListView, DetailView, FormView)
- **`AshPanel.Layouts.*`**: Layout wrappers (MinimalLayout, SidebarLayout, TopbarLayout)
- **`AshPanel.Schema.*`**: Data structures for resource/attribute/filter/action metadata

## Data Flow
1. **Introspection** -- `AshPanel.Introspection` reads Ash resource definitions via `Ash.Resource.Info` and builds `ResourceSchema` structs containing attributes, relationships, actions, and column definitions.
2. **Computer generation** -- `AshPanel.ComputerGenerator` converts the schema into AshComputer definitions that manage reactive state for list views (pagination, filtering, sorting), detail views (record loading), and form views (validation, submission).
3. **LiveView integration** -- `AshPanel.LiveView.__using__/1` injects the generated computers into the host LiveView. `setup_ash_panel/2` initializes state at mount time.
4. **Event handling** -- User interactions (page change, filter, sort) dispatch to the appropriate computer input, which triggers reactive recomputation via AshComputer and updates assigns.
5. **Rendering** -- Pluggable view components (`ListView`, `DetailView`, `FormView`) read computed assigns and delegate to behavior-implementing component modules (table, filter bar, pagination) that can be swapped at configuration time.
