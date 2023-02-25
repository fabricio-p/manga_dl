defmodule MangaDl.Monster do
  alias MangaDl.Client
  alias Finch.Response
  require Regex
  @url_regex ~r/<img[^>]+src="(https:\/\/[^"]+\/\d{3}\.(?:png|jpg))"/
  @domain "monster-manga.online"

  def domain(), do: @domain

  @spec chapter_url(String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://#{@domain}/manga/monster-chapter-#{chapter}/"
  end

  def extract_urls(chapter_url) do
    case Finch.build(
           :get,
           chapter_url,
           [{"Accept", "text/html"} | MangaDl.build_headers()]
         )
         |> Client.request() do
      {:ok, %Response{status: status} = res} when status != 200 ->
        {:error, :status, res}

      {:ok, %Response{body: data}} ->
        {:ok, Regex.scan(@url_regex, data) |> Enum.map(&Enum.at(&1, 1))}

      {:error, err} ->
        {:error, :request, err}
    end
  end

  def page_headers(_, _, _), do: []
  def page_body(_, _, _), do: nil
end
