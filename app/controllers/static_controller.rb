class StaticController < ApplicationController
  def index
    render file: Rails.root.join("public", "vite", "index.html"), layout: false
  end
end
