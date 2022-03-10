defmodule MangaDl do
  alias MangaDl.MintWrapper

  def download_chapter(
    plugin \\ MangaDl.Berserk,
    conn_agent,
    manga_dir,
    chapter
  ) do
    case plugin.extract_urls(conn_agent, plugin.chapter_url(chapter)) do
      {:ok, urls} ->
        concurrency = System.schedulers_online()
        chapter_dir = "#{String.trim_trailing(manga_dir, "/")}/#{chapter}"
        File.mkdir(chapter_dir)
        Enum.with_index(urls)
#        |> Enum.map(&download_page(&1, chapter_dir, conn_agent))
        |> Task.async_stream(
          MangaDl,
          :download_page,
          [chapter_dir, conn_agent],
          max_concurrency: concurrency,
          timeout: 1200000
        ) 
        |> Enum.to_list()
        |> Enum.filter(
          fn(result) ->
            result != :ok and result != {:ok, :ok}
          end
        )
      {:error, _err} = error ->
        error
    end
  end
  def download_page({page_url, i}, dir, conn_agent) do
    file_name = "#{i + 1}#{Enum.at(String.split(page_url, "/", -1)}"
    IO.inspect(file_name, label: :file_name)
    file_dir = "#{dir}/#{file_name}"
    case File.open(file_dir, [:write, :raw]) do
      {:ok, file} ->
        case MintWrapper.request(
          conn_agent,
          page_url,
          "GET",
          [
            {"host", "cdn.readdrstone.com"},
            {"connection", "keep-alive"},
            {
              "agent",
              "Mozilla/5.0 (Linux; Android 7.0; X53) " <>
                "AppleWebKit/537.36 (KHTML, like Gecko) " <>
                  "Chrome/91.0.4472.120 Mobile Safari/537.36"
            },
            {
              "accept",
              "image/avif,image/webp,image/apng,image/svg+xml," <>
                "image/*,*/*;q=0.8"
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
           # {"accept-language", "en"}
          ],
          nil,
          fn({:data, mint_req_ref, data}, req_ref, res)
            when mint_req_ref == req_ref ->
            :file.write(file, data)
            # like this cuz' that's what's expected from a parser function
            {:ok, false, res}
            ({:done, mint_req_ref}, req_ref, res)
            when mint_req_ref == req_ref ->
            File.close(file)
            {:ok, true, res}
            (message, mint_req_ref, res) ->
              MintWrapper.Response.parse(message, mint_req_ref, res)
          end
        ) do
          {:ok, %MintWrapper.Response{status_code: status_code}} ->
            case status_code do
              200 -> :ok
              other_status -> {:error, {:status, other_status}, i}
            end

          error ->
            # IO.inspect(error, label: :'Downloading page error')
            Tuple.append(error, i)
        end

      error ->
        # IO.inspect(error, label: :'File open error')
        Tuple.append(error, i)
    end
  end
end
