defmodule MangaDlTest.DeathNoteTest do
  use ExUnit.Case, async: true
  doctest MangaDl.DeathNote

  alias MangaDl.DeathNote

  test ".extract_urls" do
    {:ok, dict_agent} = MangaDl.ConnDict.create()
    Stream.map(1..8, &Integer.to_string/1)
    |> Stream.map(&DeathNote.chapter_url/1)
    |> Stream.map(&Task.async(DeathNote, :extract_urls, [dict_agent, &1]))
    |> Task.await_many(:infinity)
    |> Enum.each(
      fn({:ok, urls}) ->
        assert length(urls) > 0
        Enum.each(urls, fn(url) ->
          assert url =~~r{https://cdn\.\w+\.\w+/[^"]+/\d+\.jpe?g}
        end)
        ({:error, err}) ->
          throw(err)
      end
    )
    MangaDl.ConnDict.close(dict_agent)
  end
end
