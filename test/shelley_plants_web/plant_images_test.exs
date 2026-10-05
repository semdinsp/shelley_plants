defmodule ShelleyPlantsWeb.PlantImagesTest do
  use ExUnit.Case, async: true

  alias ShelleyPlantsWeb.PlantImages

  describe "thumb_url/1" do
    test "uses the thumbnail when one exists" do
      assert PlantImages.thumb_url("/images/plants/coreopsis_lanceolata_2.jpg") ==
               "/images/plants/thumbs/coreopsis_lanceolata_2.jpg"
    end

    test "maps non-jpg photos to their jpg thumbnail" do
      assert PlantImages.thumb_url("/images/plants/agastache_foeniculum.png") ==
               "/images/plants/thumbs/agastache_foeniculum.jpg"
    end

    test "falls back to the full photo when no thumbnail exists" do
      assert PlantImages.thumb_url("/images/plants/just-uploaded.jpg") ==
               "/images/plants/just-uploaded.jpg"
    end

    test "passes through external URLs and nil" do
      assert PlantImages.thumb_url("https://example.com/a.jpg") == "https://example.com/a.jpg"
      assert PlantImages.thumb_url(nil) == nil
    end
  end
end
