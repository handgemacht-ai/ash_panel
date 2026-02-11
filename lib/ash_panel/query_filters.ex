defmodule AshPanel.QueryFilters do
  @moduledoc """
  Utilities for applying filters to Ash queries.

  Converts filter specifications (field, operator, value) into Ash query filters.
  """

  @doc """
  Applies a list of filter specs to an Ash query.

  ## Filter Spec Format

  Each filter spec is a map with:
  - `field` - The attribute to filter on
  - `operator` - One of `:equals`, `:contains`, `:gte`, `:lte`, `:gt`, `:lt`, `:in`
  - `value` - The value to filter by

  ## Examples

      iex> query = User
      iex> filters = [
      ...>   %{field: :email, operator: :contains, value: "john"},
      ...>   %{field: :age, operator: :gte, value: 18}
      ...> ]
      iex> QueryFilters.apply_filters(query, filters)
      #Ash.Query<...>
  """
  def apply_filters(query, filters) when filters == [], do: query

  def apply_filters(query, filters) do
    require Ash.Query

    Enum.reduce(filters, query, fn %{field: field, operator: op, value: value}, q ->
      apply_single_filter(q, field, op, value)
    end)
  end

  # Private functions

  defp apply_single_filter(query, field, :equals, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) == ^value)
  end

  defp apply_single_filter(query, field, :contains, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, contains(^ref(field), ^value))
  end

  defp apply_single_filter(query, field, :gte, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) >= ^value)
  end

  defp apply_single_filter(query, field, :lte, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) <= ^value)
  end

  defp apply_single_filter(query, field, :gt, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) > ^value)
  end

  defp apply_single_filter(query, field, :lt, value) when is_atom(field) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) < ^value)
  end

  defp apply_single_filter(query, field, :in, values) when is_atom(field) and is_list(values) do
    import Ash.Expr
    require Ash.Query

    Ash.Query.filter(query, ^ref(field) in ^values)
  end

  # Fallback: ignore unknown operators
  defp apply_single_filter(query, _field, _op, _value), do: query
end
