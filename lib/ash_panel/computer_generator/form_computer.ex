defmodule AshPanel.ComputerGenerator.FormComputer do
  @moduledoc """
  Generates a form computer from a ResourceSchema.

  Creates a computer that handles create and update forms with validation
  and field management.

  ## Generated Computer: `:form_view`

  ### Inputs
  - `record_id` - ID of record to edit (nil for create)
  - `form_data` - Map of field values
  - `show_form` - Whether to show the form
  - `actor` - Current user for authorization

  ### Vals
  - `record` - Existing record (for update)
  - `mode` - :create or :update
  - `fields` - Form field definitions
  - `errors` - Validation errors
  - `submitting?` - Whether form is being submitted
  - `success?` - Whether last submission succeeded
  - `resource_schema` - The ResourceSchema for this resource

  ### Events
  - `open_create` - Open form in create mode
  - `open_edit` - Open form in edit mode with record ID
  - `set_field` - Update a field value
  - `submit` - Submit the form
  - `close` - Close the form
  - `reset` - Reset form to initial state
  """

  defmacro __using__(opts) do
    caller = __CALLER__

    eval = fn ast ->
      {value, _} = Code.eval_quoted(ast, [], caller)
      value
    end

    resource = opts |> Keyword.fetch!(:resource) |> eval.()
    domain = opts |> Keyword.fetch!(:domain) |> eval.()
    overrides = opts |> Keyword.get(:overrides, quote(do: %{})) |> eval.()
    authorize? = opts |> Keyword.get(:authorize?, quote(do: true)) |> eval.()

    quote do
      # Build the resource schema at compile time
      @form_view_schema AshPanel.Introspection.build_resource_schema(
                          unquote(resource),
                          unquote(domain),
                          overrides: unquote(Macro.escape(overrides))
                        )
      @form_view_authorize? unquote(authorize?)

      # Get default values from attributes
      @form_view_defaults @form_view_schema.attributes
                          |> Enum.filter(& &1.show_in_form?)
                          |> Enum.reject(&is_nil(&1.default))
                          |> Map.new(&{&1.name, &1.default})

      computer :form_view do
        input :record_id do
          initial(nil)
          description("ID of record to edit (nil for create)")
        end

        input :form_data do
          initial(@form_view_defaults)
          description("Map of field values")
        end

        input :show_form do
          initial(false)
          description("Whether to show the form")
        end

        input :actor do
          initial(nil)
          description("Current user for authorization")
        end

        input :errors do
          initial(%{})
          description("Validation errors by field")
        end

        input :submitting? do
          initial(false)
          description("Whether form is being submitted")
        end

        input :success? do
          initial(false)
          description("Whether last submission succeeded")
        end

        val :record do
          description("Existing record (for update mode)")

          compute(fn %{record_id: record_id, actor: actor} ->
            case record_id do
              nil ->
                nil

              id ->
                try do
                  unquote(resource)
                  |> Ash.get!(id,
                    domain: unquote(domain),
                    actor: actor,
                    authorize?: @form_view_authorize?
                  )
                rescue
                  _ -> nil
                end
            end
          end)
        end

        val :mode do
          description("Form mode: :create or :update")

          compute(fn %{record_id: record_id} ->
            if is_nil(record_id), do: :create, else: :update
          end)
        end

        val :fields do
          description("Form field definitions with current values")

          compute(fn %{form_data: form_data, record: record} ->
            @form_view_schema.attributes
            |> Enum.filter(& &1.show_in_form?)
            |> Enum.map(fn attr ->
              # Get current value (from form_data, record, or default)
              value =
                Map.get(form_data, attr.name) ||
                  (record && Map.get(record, attr.name)) ||
                  attr.default

              Map.put(attr, :current_value, value)
            end)
          end)
        end

        val :resource_schema do
          description("The ResourceSchema for this resource")

          compute(fn _values ->
            @form_view_schema
          end)
        end

        val :create_action do
          description("The primary create action")

          compute(fn _values ->
            @form_view_schema.actions
            |> Enum.find(&(&1.type == :create && &1.primary?))
          end)
        end

        val :update_action do
          description("The primary update action")

          compute(fn _values ->
            @form_view_schema.actions
            |> Enum.find(&(&1.type == :update && &1.primary?))
          end)
        end

        event :open_create do
          handle(fn _values, _payload ->
            %{
              record_id: nil,
              form_data: @form_view_defaults,
              show_form: true,
              errors: %{},
              success?: false
            }
          end)
        end

        event :open_edit do
          handle(fn _values, %{"id" => id} ->
            # Form data will be populated from record when it loads
            %{
              record_id: id,
              form_data: %{},
              show_form: true,
              errors: %{},
              success?: false
            }
          end)
        end

        event :set_field do
          handle(fn %{form_data: form_data}, %{"field" => field, "value" => value} ->
            new_state =
              try do
                field_atom = String.to_existing_atom(field)
                new_form_data = Map.put(form_data, field_atom, value)

                %{form_data: new_form_data, errors: %{}}
              rescue
                ArgumentError ->
                  %{}
              end

            new_state
          end)
        end

        event :submit do
          handle(fn %{
                      mode: mode,
                      record_id: record_id,
                      form_data: form_data,
                      actor: actor
                    },
                    _payload ->
            # This is a simplified version - in reality, you'd want to:
            # 1. Validate the form data
            # 2. Call the appropriate action
            # 3. Handle errors
            # 4. Update state accordingly

            # For now, we'll mark as submitting and let the LiveView handle the actual submission
            %{submitting?: true}
          end)
        end

        event :close do
          handle(fn _values, _payload ->
            %{
              show_form: false,
              form_data: @form_view_defaults,
              errors: %{},
              success?: false
            }
          end)
        end

        event :reset do
          handle(fn %{record: record}, _payload ->
            # Reset to record values (for update) or defaults (for create)
            initial_data =
              if record do
                @form_view_schema.attributes
                |> Enum.filter(& &1.show_in_form?)
                |> Map.new(&{&1.name, Map.get(record, &1.name)})
              else
                @form_view_defaults
              end

            %{form_data: initial_data, errors: %{}}
          end)
        end

        event :new do
          handle(fn _values, _payload ->
            %{
              record_id: nil,
              form_data: @form_view_defaults,
              show_form: true,
              errors: %{},
              success?: false
            }
          end)
        end

        event :edit do
          handle(fn _values, %{"id" => id} ->
            %{
              record_id: id,
              form_data: %{},
              show_form: true,
              errors: %{},
              success?: false
            }
          end)
        end

        event :update_field do
          handle(fn assigns, payload ->
            AshPanel.ComputerGenerator.FormComputer.update_field(assigns, payload)
          end)
        end
      end
    end
  end

  @doc false
  def update_field(%{form_data: form_data}, %{"field" => field, "value" => value}) do
    try do
      field_atom = String.to_existing_atom(field)
      new_form_data = Map.put(form_data, field_atom, value)

      %{form_data: new_form_data, errors: %{}}
    rescue
      ArgumentError ->
        %{}
    end
  end
end
