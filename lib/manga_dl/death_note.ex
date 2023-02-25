defmodule MangaDl.DeathNote do
  alias MangaDl.Client
  require Regex
  @url_regex ~r[src="(https://cdn\.\w+\.\w+/[^"\]*/\d+\.jpe?g)"]
  @domain "death-note-online.com"

  def domain(), do: @domain

  @spec chapter_url(String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://#{@domain}/manga/death-note-chapter-#{chapter}/"
  end

  @spec extract_urls(String.t()) ::
          {:ok, [String.t()]}
          | {:error, MangaDl.error_kind(), Any.t()}
  def extract_urls(chapter_url) do
    case Finch.build(:get, chapter_url, MangaDl.build_headers())
         |> Client.request() do
      {:ok, %Finch.Response{status: status} = res} when status != 200 ->
        {:error, :status, res}

      {:ok, %Finch.Response{body: data}} ->
        urls =
          Regex.scan(@url_regex, data)
          |> Enum.map(&Enum.at(&1, 1))
          |> Enum.uniq()

        {:ok, urls}

      {:error, err} ->
        {:error, :request, err}
    end
  end

  def page_headers(_, _, _), do: []
  def page_body(_, _, _), do: nil
end
