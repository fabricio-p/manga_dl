defmodule MangaDl.Berserk do
  alias MangaDl.Client
  require Regex
  @url_regex ~r[<img\s+class="pages__img"\s+src="(https://.*/\w+\.(jpe?g|png))]
  @domain "readberserk.com"

  def domain(), do: @domain

  @spec chapter_url(chapter :: String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://readberserk.com/chapter/berserk-chapter-#{chapter}/"
  end

  def extract_urls(chapter_url) do
    case Finch.build(:get, chapter_url, MangaDl.build_headers())
         |> Client.request() do
      {:ok, %Finch.Response{status: 200, body: data}} ->
        {:ok, Regex.scan(@url_regex, data) |> Enum.map(&Enum.at(&1, 1))}

      {:ok, res} ->
        {:error, :status, res}

      {:error, err} ->
        {:error, :request, err}
    end
  end

  def page_headers(_, _, _), do: []
  def page_body(_, _, _), do: nil
end
