class PartsController < ApplicationController
  def shortages
    render inertia: "Parts/Shortages", props: Parts::ShortageDelayReport.call
  end
end
