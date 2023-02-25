defmodule MangaDl.DoctorStone do
  alias MangaDl.Client
  require Regex
  @url_regex ~r[\.com/.*/(?:DrS_(?:\d+_?)+-?)?\d+\.(?:jpe?g|png)]
  @domain "ww4.readdrstone.com"

  def domain(), do: @domain

  @spec chapter_url(chapter :: String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://#{@domain}/chapter/dr-stone-chapter-#{chapter}/"
  end

  @spec extract_urls(content :: String.t()) ::
          {:ok, [String.t()]}
          | {:error, MangaDl.error_kind(), Any.t()}
  def extract_urls(chapter_url) do
    case Finch.build(
           :get,
           chapter_url,
           [{"accept-language", "en"} | MangaDl.build_headers()]
         )
         |> Client.request() do
      {:ok, %Finch.Response{status: status} = res} when status != 200 ->
        {:error, :status, res}

      {:ok, %Finch.Response{body: data}} ->
        urls =
          Regex.scan(@url_regex, data)
          |> Stream.map(&Enum.at(&1, 0))
          |> Stream.map(fn url ->
            case url do
              ".com/" <> rest ->
                "https://cdn.readdrstone.com/" <> rest

              _ ->
                url
            end
          end)
          |> Enum.to_list()

        {:ok, urls}

      {:error, err} ->
        {:error, :request, err}
    end
  end

  def page_headers(_, _, _), do: []
  def page_body(_, _, _), do: nil
end
