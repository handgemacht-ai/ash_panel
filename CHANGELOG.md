# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-02-11

### Added

- Auto-discovery of Ash resources via introspection system
- AshComputer-powered reactive state management (ListComputer, DetailComputer, FormComputer)
- `ResourceLive` macro for zero-configuration CRUD interfaces
- `AshPanel.Router` with `ash_panel_resource` macro for route generation
- Component behavior system (`TableBehavior`, `FilterBarBehavior`, `PaginationBehavior`)
- Default components: `DefaultTable`, `DefaultFilterBar`, `DefaultPagination`, `DefaultPageSizeSelector`
- Container views: `ListView`, `DetailView`, `FormView`
- Three built-in layouts: `SidebarLayout`, `TopbarLayout`, `MinimalLayout`
- Pagination, filtering, sorting, and search support
- Authorization-aware with Ash policy integration
- Smart field type inference and formatter detection

[Unreleased]: https://github.com/handgemacht-ai/ash_panel/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/handgemacht-ai/ash_panel/releases/tag/v0.1.0
