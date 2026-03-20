module Api
  class DraftsController < BaseController
    # POST /api/drafts/bulk
    def bulk_create
      drafts_data = params[:drafts] || []
      created = []

      drafts_data.each do |draft_data|
        draft = Draft.create(
          contact_id: draft_data[:contact_id],
          subject: draft_data[:subject],
          body: draft_data[:body],
          status: :draft
        )
        created << { id: draft.id, contact_id: draft.contact_id } if draft.persisted?
      end

      render json: { created: created.size, drafts: created }
    end
  end
end
