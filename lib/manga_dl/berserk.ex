defmodule MangaDl.Berserk do
  require Regex
  @url_regex ~r[<img\s+class="pages__img"\s+src="(https://.*/\w+\.jpe?g)]
  @domain "readberserk.com"

  def domain(), do: @domain

  @spec chapter_url(chapter :: String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://readberserk.com//chapter/berserk-chapter-#{chapter}/"
  end

  # @spec extract_urls(content :: String.t()) ::
  #         {:ok, [String.t()]}
  #         | {:error, Any.t()}
  def extract_urls(dict_agent, chapter_url) do
    r = _extract_urls(dict_agent, chapter_url)
    IO.inspect(r, label: :"extract_urls result")
  end
  def _extract_urls(dict_agent, chapter_url) do
    case MangaDl.MintWrapper.request(
           dict_agent,
           chapter_url,
           "GET",
           [
             {"Range", "bytes=45650-"},
             {"Connection", "Keep-Alive"},
             {"Agent", "Mozilla/5.0"}
           ]
    ) do
      {:ok, res = %MangaDl.MintWrapper.Response{status_code: 200}} ->
        #IO.inspect(res.body)
        content = Enum.join(res.data, "")
        urls = Enum.map(Regex.scan(@url_regex, content), &Enum.at(&1, 1))
        {:ok, urls}

      {:ok, res} ->
        {:error, res}

      {:error, _} = error ->
        error

      default -> IO.inspect(default, label: :default_case)
    end
  end
end
