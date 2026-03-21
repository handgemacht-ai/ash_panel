# Product Skill -- ash_panel

## Product Summary
A composable resource management UI library for Ash Framework applications. It auto-generates CRUD admin interfaces from Ash resource definitions with zero configuration, while offering four progressive levels of customization (config DSL, component swapping, computer extension, fully custom). Targets Elixir developers building Phoenix LiveView apps with Ash.

## Domain/Feature Index
| Feature | Route/Entry | Description |
|---------|------------|-------------|
| Auto-discovery | `AshPanel.Introspection` | Introspects Ash resources to generate schemas, columns, filters automatically |
| List view | `AshPanel.Views.ListView` | Paginated, filterable, sortable table of records |
| Detail view | `AshPanel.Views.DetailView` | Single-record view with relationships and actions |
| Form view | `AshPanel.Views.FormView` | Create/update forms with validation |
| Router macros | `AshPanel.Router` | `ash_panel_resource` generates RESTful LiveView routes (index/show/new/edit) |
| ResourceLive | `AshPanel.ResourceLive` | Complete CRUD LiveView in one `use` macro |
| Component behaviors | `AshPanel.Components.*Behavior` | Swappable table, filter bar, pagination components |
| Layouts | `AshPanel.Layouts.*` | Minimal, sidebar, and topbar layout wrappers |
| Reactive state | `AshPanel.ComputerGenerator` | AshComputer-powered reactive state for all views |
| Filter builder | `AshPanel.Introspection.FilterDefinitionBuilder` | Infers filter types from attribute types |

## Core Entities
- **ResourceSchema**: Introspected metadata for an Ash resource (attributes, relationships, actions, columns)
- **AttributeSchema**: Metadata for a single resource attribute
- **FilterDefinition**: Filter configuration inferred from attribute types
- **ColumnDefinition**: Table column configuration
- **ActionSchema**: Metadata for resource actions
- **RelationshipSchema**: Metadata for resource relationships

## External Integrations
- **Ash Framework**: Core dependency for resource introspection and data operations
- **AshComputer**: Reactive state management engine
- **Phoenix LiveView**: Runtime rendering and real-time updates

## Known Limitations
- Library only (no standalone app) -- must be integrated into a Phoenix + Ash host application
- Views are LiveView-only; no server-rendered or REST API mode
- Delete action is stubbed (TODO in ResourceLive)
- No built-in authentication -- relies on host app's auth pipeline
- Default components use basic HTML; no CSS framework bundled
