defmodule EtheloApi.CollectiveIdentity do
  @moduledoc """
  Calculates collective identity steps based on step count and vice versa.
  """
  require Decimal

  def delta(nil, _), do: nil
  def delta(_, nil), do: nil
  def delta(min, max) when is_float(min), do: delta(Decimal.from_float(min), max)
  def delta(min, max) when is_float(max), do: delta(min, Decimal.from_float(max))
  def delta(min, max) when is_integer(min), do: delta(Decimal.new(min), max)
  def delta(min, max) when is_integer(max), do: delta(min, Decimal.new(max))

  def delta(max, min) do
    max |> Decimal.sub(min) |> Decimal.abs()
  end

  def step_count(min, max, step) do
    delta = delta(max, min)
    step_count(delta, step)
  end

  def step_count(nil, _), do: nil
  def step_count(_, nil), do: nil

  def step_count(delta, step) when is_float(delta),
    do: step_count(Decimal.from_float(delta), step)

  def step_count(delta, step) when is_float(step), do: step_count(delta, Decimal.from_float(step))
  def step_count(delta, step) when is_integer(delta), do: step_count(Decimal.new(delta), step)
  def step_count(delta, step) when is_integer(step), do: step_count(delta, Decimal.new(step))

  def step_count(delta, step) do
    delta |> Decimal.div_int(step)
  end

  def step_value(min, max, step_count) do
    delta = delta(max, min)
    step_value(delta, step_count)
  end

  def step_value(nil, _), do: nil
  def step_value(_, nil), do: nil

  def step_value(delta, step_count) when is_float(delta),
    do: step_value(Decimal.from_float(delta), step_count)

  def step_value(delta, step_count) when is_float(step_count),
    do: step_value(delta, Decimal.from_float(step_count))

  def step_value(delta, step_count) when is_integer(delta),
    do: step_value(Decimal.new(delta), step_count)

  def step_value(delta, step_count) when is_integer(step_count),
    do: step_value(delta, Decimal.new(step_count))

  def step_value(delta, step_count) do
    delta = Decimal.new(delta)
    step_count = Decimal.new(step_count)

    delta |> Decimal.div(step_count) |> Decimal.round(5, :floor)
  end
end
