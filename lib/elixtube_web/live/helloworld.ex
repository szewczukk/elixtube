defmodule ElixtubeWeb.HelloWorld do
  alias Phoenix.PubSub
  alias Elixtube.TranscodeServer
  use ElixtubeWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Original</h1>
    <%= if @uploaded_path do %>
      <video width="320" height="240" controls autoplay class="w-full">
        <source src={@uploaded_path} type="video/mp4" />
      </video>
    <% end %>

    <form id="upload-form" phx-submit="upload" phx-change="validate" class="m-4">
      <.live_file_input upload={@uploads.video} />
      <button type="submit" class="border px-8 py-1 bg-slate-300 border-slate-400">Upload</button>
    </form>

    <div class="flex flex-col gap-4 w-full">
      <div class="w-full">
        <h1>360p</h1>
        <%= if @transcoded_360 do %>
          <video width="320" height="240" controls autoplay class="w-full">
            <source src={@transcoded_360} type="video/mp4" />
          </video>
        <% end %>
      </div>

      <div class="w-full">
        <h1>480p</h1>
        <%= if @transcoded_480 do %>
          <video width="320" height="240" controls autoplay class="w-full">
            <source src={@transcoded_480} type="video/mp4" />
          </video>
        <% end %>
      </div>

      <div class="w-full">
        <h1>720p</h1>
        <%= if @transcoded_720 do %>
          <video width="320" height="240" controls autoplay class="w-full">
            <source src={@transcoded_720} type="video/mp4" />
          </video>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    PubSub.subscribe(Elixtube.PubSub, "video_transcoded")

    {:ok,
     socket
     |> assign(:uploaded_path, nil)
     |> assign(:transcoded_360, nil)
     |> assign(:transcoded_480, nil)
     |> assign(:transcoded_720, nil)
     |> allow_upload(:video, accept: ~w(.mp4), max_entries: 1)}
  end

  def handle_event("upload", _params, socket) do
    [file_path | _] =
      consume_uploaded_entries(socket, :video, fn %{path: path}, _entry ->
        dest = Path.join("priv/static/uploads", Path.basename(path))
        dest = "#{dest}.mp4"

        File.cp!(path, dest)

        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    for quality <- ["720", "480", "360"] do
      TranscodeServer.transcode(file_path, quality)
    end

    {:noreply,
     socket
     |> assign(:uploaded_path, file_path)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_info({:transcoded, new_path, quality}, socket) do
    socket =
      case quality do
        "720" -> assign(socket, :transcoded_720, new_path)
        "480" -> assign(socket, :transcoded_480, new_path)
        "360" -> assign(socket, :transcoded_360, new_path)
      end

    {:noreply, socket}
  end
end
