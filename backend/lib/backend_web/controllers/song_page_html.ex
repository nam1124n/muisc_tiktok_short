defmodule BackendWeb.SongPageHTML do
  @moduledoc """
  Renders the basic admin pages for generated songs.

  Phoenix 1.8 uses this HTML module to embed templates.
  """

  use BackendWeb, :html

  embed_templates "../templates/song_page/*"
end
