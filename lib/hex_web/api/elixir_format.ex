defmodule HexWeb.API.ElixirFormat do
  @doc """
  Encode an elixir term that can be safely deserialized on another machine.
  """
  @spec encode(term) :: String.t
  def encode(term) do
    HexWeb.Util.binarify(term)
    |> inspect(limit: :infinity, binaries: :as_strings)
  end

  @doc """
  Safely deserialize an elixir formatted string.
  """
  @spec decode(String.t) :: term
  def decode("") do
    {:ok, nil}
  end

  def decode(string) do
    case Code.string_to_quoted(string, existing_atoms_only: true) do
      {:ok, ast} ->
        safe_eval(ast)
      _ ->
        {:error, "malformed elixir"}
    end
  end

  defp safe_eval(ast) do
    if safe_term?(ast) do
      result = Code.eval_quoted(ast)
               |> elem(0)
      {:ok, result}
    else
      {:error, "unsafe elixir"}
    end
  end

  defp safe_term?({func, _, terms}) when func in [:{}, :%{}] and is_list(terms) do
    Enum.all?(terms, &safe_term?/1)
  end

  defp safe_term?(nil), do: true
  defp safe_term?(term) when is_number(term), do: true
  defp safe_term?(term) when is_binary(term), do: true
  defp safe_term?(term) when is_boolean(term), do: true
  defp safe_term?(term) when is_list(term), do: Enum.all?(term, &safe_term?/1)
  defp safe_term?(term) when is_tuple(term), do: Enum.all?(Tuple.to_list(term), &safe_term?/1)
  defp safe_term?(_), do: false
end
