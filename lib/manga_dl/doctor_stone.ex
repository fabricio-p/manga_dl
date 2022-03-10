defmodule MangaDl.DoctorStone do
  require Regex
  @url_regex ~r[\.com/.*/(?:DrS_(?:\d+_?)+-?)?\d+\.(?:jpe?g|png)]
  @domain "ww3.readdrstone.com"

  def domain(), do: @domain

  @spec chapter_url(chapter :: String.t()) :: String.t()
  def chapter_url(chapter) do
    "https://ww3.readdrstone.com/chapter/dr-stone-chapter-#{chapter}/"
  end

  # @spec extract_urls(content :: String.t()) ::
  #         {:ok, [String.t()]}
  #         | {:error, Any.t()}
  def extract_urls(dict_agent, chapter_url) do
    case MangaDl.MintWrapper.request(
           dict_agent,
           chapter_url,
           "GET",
           [
             {"host", @domain},
             {"connection", "keep-alive"},
             {
               "agent",
               "Mozilla/5.0 (Linux; Android 7.0; X53) " <>
                 "AppleWebKit/537.36 (KHTML, like Gecko) " <>
                   "Chrome/91.0.4472.120 Mobile Safari/537.36"
             },
             # {
             #   "sec-ch-ua",
             #   ~s[" Not;A Brand";v="99", "Google Chrome";v="91", ] <> 
             #     ~s["Chromium";v="91"],
             # },
             # {"sec-ch-ua-mobile", "?1"},
             # {"dnt", "1"},
             # {"save-data", "on"},
             # {"upgrade-insecure-requests", "1"},
             # {"sec-fetch-site", "none"},
             # {"sec-fetch-mode", "navigate"},
             # {"sec-fetch-user", "?1"},
             # {"sec-fetch-dest", "document"},
             # {"accept-encoding", "utf-8"},
             {"accept-language", "en"}
           ]
    ) do
      {:ok, res = %MangaDl.MintWrapper.Response{status_code: 200}} ->
        content = Enum.join(res.data, "")
        # IO.inspect(content, label: :content)
        File.write("foo3.html", content)
        urls = Regex.scan(@url_regex, content)
               |> Enum.map(&Enum.at(&1, 0))
               |> Enum.map(fn(url) ->
                 case url do
                   ".com/" <> rest ->
                     "https://cdn.readdrstone.com/" <> rest
                   _ ->
                     url
                 end
               end)
        {:ok, urls}

      {:ok, res} ->
        {:error, res}

      {:error, _} = error ->
        error

      default -> IO.inspect(default, label: :default_case)
    end
  end
end
