defmodule MangaDl.MintWrapper do
  alias Mint.HTTP
  require Logger

  defmacrop register_conn(host, conn) do
    quote do
#       Process.put(
#         @conn_key,
#         Map.put(
#           Process.get(@conn_key) || %{},
#           unquote(host),
#           unquote(conn)
#         )
#       )
      MangaDl.ConnDict.register(
        conn_agent,
        unquote(host),
        unquote(conn)
      )
    end
  end

  defmacrop has_conn(host) do
    quote do
      # Map.has_key?(Process.get(@conn_key) || %{}, unquote(host))
      MangaDl.ConnDict.has(conn_agent, unquote(host))
    end
  end

  defmacrop get_conn(host) do
    quote do: MangaDl.ConnDict.get(conn_agent, unquote(host))
  end

  defmodule Response do
    defstruct status_code: nil,
              headers: nil,
              data: nil

    @type t :: %Response{
            status_code: Integer.t(),
            headers: {String.t(), String.t()},
            data: Any.t()
          }
    def parse(
          {:status, mint_req_ref, status_code},
          req_ref,
          res = %Response{}
        ) when req_ref == mint_req_ref do
      {:ok, false, %{res | status_code: status_code}}
    end

    def parse(
          {:headers, mint_req_ref, headers},
          req_ref,
          res = %Response{}
        ) when req_ref == mint_req_ref do
      {:ok, false, %{res | headers: headers}}
    end

    def parse({:data, mint_req_ref, data}, req_ref, res = %Response{})
          when req_ref == mint_req_ref do
            {
              :ok,
              false,
              %{
                res |
                data: if(res.data == nil,
                         do: [data],
                         else: [data | res.data])
              }
            }
    end

    def parse({:done, mint_req_ref}, req_ref, res = %Response{})
          when req_ref == mint_req_ref do
            {
              :ok,
              true,
              %{
                res |
                data: if(res.data == nil,
                         do: [],
                         else: Enum.reverse(res.data))
              }
            }
    end

    def parse({_, mint_req_ref}, req_ref, _)
        when mint_req_ref != req_ref, do: {:error, nil, :invalid_ref}

    def parse({_, mint_req_ref, _}, req_ref, _)
        when mint_req_ref != req_ref, do: {:error, nil, :invalid_ref}
  end

  defp recv_response(conn, req_ref, res \\ %Response{}, cb) do
    receive do
      message ->
        case HTTP.stream(conn, message) do
          :unknown ->
            # IO.inspect(message, label: :"unknown message")
            # :unknown
            recv_response(conn, req_ref, res, cb)

          {:ok, conn, mint_messages} ->
            case Enum.reduce_while(
              mint_messages,
              {:ok, false, res},
              fn(mint_message, {:ok, false, res}) ->
                case cb.(mint_message, req_ref, res) do
                  {:ok, finished, _res} = r ->
                    {if(finished, do: :halt, else: :cont), r}
                  {:error, _, _err} = error -> {:halt, error}
                end
              end
            ) do
              {:ok, true, res} -> {:ok, res, conn}
              {:ok, false, res} -> recv_response(conn, req_ref, res, cb)
              {:error, _, _err} = error -> error
            end
        end
    end
  end

  defp scheme_atom(scheme) do
    case scheme do
      "http" -> :http
      "https" -> :https
      _ -> throw(:invalid_scheme)
    end
  end

  defp path(uri) do
    IO.iodata_to_binary([
      if(uri.path != nil, do: uri.path, else: "/"),
      if(uri.query != nil, do: ["?" | uri.query], else: []),
      if(uri.fragment != nil, do: ["#" | uri.fragment], else: [])
    ])
  end

  def request(
    conn_agent,
    uri_or_url,
    method \\ "GET",
    headers \\ [],
    body \\ nil,
    cb \\ &Response.parse/3
  )

  def request(conn_agent, url, method, headers, body, cb)
      when is_binary(url) and
             method in ~w[GET POST PUT DELETE PATCH OPTIONS HEAD] and
             is_list(headers) and (is_binary(body) or body == nil) do
    request(conn_agent, URI.new(url), method, headers, body, cb)
  end

  def request(conn_agent, {:ok, uri}, method, headers, body, cb)
      when method in ~w[GET POST PUT DELETE PATCH OPTIONS HEAD] and
             is_list(headers) and (is_binary(body) or body == nil) do
    request(conn_agent, uri, method, headers, body, cb)
  end

  def request(_, {:error, _err} = error, _, _, _, _), do: error

  import MangaDl.ConnDict, [:has, :get, :register]

  def request(conn_agent, uri = %URI{}, method, headers, body, cb)
      when method in ~w[GET POST PUT DELETE PATCH OPTIONS HEAD] and
             is_list(headers) and (is_binary(body) or body == nil) do
    conn_atom = {
      HTTP.connect(scheme_atom(uri.scheme), uri.host, uri.port),
      true
    }
#       if has(conn_agent, uri.host) and
#          Map.get(get(conn_agent, uri.host), :state) != :closed do
#         {{:ok, get(conn_agent, uri.host)}, false}
#       else
#         {HTTP.connect(scheme_atom(uri.scheme), uri.host, uri.port), true}
#       end

    case conn_atom do
      {{:ok, conn}, is_new} ->
        if is_new do
          # register(conn_agent, uri.host, conn)
        end

        case HTTP.request(conn, method, path(uri), headers, body) do
          {:ok, conn, req_ref} ->
            case recv_response(conn, req_ref, cb) do
              {:ok, res, conn} ->
                {:ok, res}
              error ->
                error
            end
          {:error, _} = error -> error
          {:error, _, _} = error -> error
        end

      {{:error, err}, _} ->
        {:error, err}
    end
  end
end
