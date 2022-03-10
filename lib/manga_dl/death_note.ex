defmodule MangaDl.DeathNote do
  require Regex
  @url_regex ~r[src="(https://cdn\.\w+\.\w+/[^"\]*/\d+\.jpe?g)"]
  @domain "death-note-online.com"

  def domain(), do: @domain

  @spec chapter_url(chapter :: String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://#{@domain}/manga/death-note-chapter-#{chapter}/"
  end

  def extract_urls(dict_agent, chapter_url) do
    case MangaDl.MintWrapper.request(
           dict_agent,
           chapter_url,
           "GET",
           [
             {"Connection", "Keep-Alive"},
             {"Agent", "Mozilla/5.0"}
           ]
    ) do
      {:ok, res = %MangaDl.MintWrapper.Response{status_code: 200}} ->
        #IO.inspect(res.body)
        content = Enum.join(res.data, "")
        urls = Enum.map(Regex.scan(@url_regex, content), &Enum.at(&1, 1))
               |> Enum.uniq()
        {:ok, urls}

      {:ok, res} ->
        {:error, res}

      {:error, _} = error ->
        error

      {:error, _, _} = error ->
        error
    end
  end
end
