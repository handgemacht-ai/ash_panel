# Index

## Source Directories
- `lib/ash_panel/` -- Main application code
- `lib/ash_panel/components/` -- Swappable UI components with behavior contracts
- `lib/ash_panel/computers/` -- Standalone AshComputer modules (filters, pagination)
- `lib/ash_panel/computer_generator/` -- Per-view computer generators (list, detail, form)
- `lib/ash_panel/introspection/` -- Resource introspection helpers (filter builder)
- `lib/ash_panel/layouts/` -- Layout components (minimal, sidebar, topbar)
- `lib/ash_panel/schema/` -- Schema structs for resource metadata
- `lib/ash_panel/views/` -- Pre-built view components (list, detail, form)
- `test/` -- ExUnit tests
- `test/support/` -- Test helpers and fixtures

## Key Config Files
- `mix.exs` -- Project definition, deps, hex package metadata
- `mix.lock` -- Dependency lock file
- `.formatter.exs` -- Code formatter config

## Important Files
- `lib/ash_panel.ex` -- Library entry point, module docs
- `lib/ash_panel/introspection.ex` -- Core resource introspection: discovers resources, builds ResourceSchema
- `lib/ash_panel/computer_generator.ex` -- Macro for generating AshComputer definitions from schemas
- `lib/ash_panel/live_view.ex` -- `use AshPanel.LiveView` macro: wires computers into LiveViews
- `lib/ash_panel/resource_live.ex` -- `use AshPanel.ResourceLive` macro: full CRUD LiveView with routing
- `lib/ash_panel/router.ex` -- `ash_panel_resource` route macro
- `lib/ash_panel/components/table_behavior.ex` -- Table component behavior contract
- `lib/ash_panel/components/filter_bar_behavior.ex` -- Filter bar behavior contract
- `lib/ash_panel/components/pagination_behavior.ex` -- Pagination behavior contract
- `lib/ash_panel/schema/resource_schema.ex` -- Core schema struct for introspected resources
- `README.md` -- Usage guide with customization levels
- `ROUTER_EXAMPLE.md` -- Multi-resource router setup example
- `ZERO_CONFIG_EXAMPLE.md` -- Minimal setup walkthrough
