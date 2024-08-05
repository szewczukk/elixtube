defmodule Elixtube.TranscodeServer do
  alias Phoenix.PubSub
  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def transcode(file_path, quality) do
    GenServer.cast(__MODULE__, {:transcode, file_path, quality})
  end

  def handle_cast({:transcode, file_path, quality}, _state) do
    new_path = "/transcoded/#{Path.basename(file_path)}--#{quality}p.mp4"

    {:ok, cwd} = File.cwd()

    base_path = Path.join(cwd, "/priv/static")

    width =
      case quality do
        "720" -> "1280"
        "480" -> "640"
        "360" -> "640"
      end

    System.cmd(
      "ffmpeg",
      [
        "-i",
        "#{base_path}#{file_path}",
        "-vf",
        "scale=w=#{width}:h=#{quality}:force_original_aspect_ratio=decrease:force_divisible_by=2",
        "-sws_flags",
        "lanczos",
        "#{base_path}#{new_path}"
      ]
    )

    PubSub.broadcast(Elixtube.PubSub, "video_transcoded", {:transcoded, new_path, quality})

    {:noreply, new_path}
  end
end
