defmodule MangaDlTest.BerserkTest do
  use ExUnit.Case, async: true
  doctest MangaDl.Berserk

  alias MangaDl.Berserk

  test ".extract_urls" do
    {:ok, dict_agent} = MangaDl.ConnDict.create()

    Enum.map(~w[a0 b0 d0 e0 001 002 003 004 005], &Berserk.chapter_url/1)
    |> Enum.map(&Task.async(Berserk, :extract_urls, [dict_agent, &1]))
    |> Task.await_many(16000)
    |> Enum.each(fn
      {:ok, urls} ->
        assert length(urls) > 0

        Enum.each(urls, fn url ->
          assert url =~ ~r{https://.*/.*/\w+\.jpe?g}
        end)

      {:error, err} ->
        throw(err)
    end)

    MangaDl.ConnDict.close(dict_agent)
  end
end
