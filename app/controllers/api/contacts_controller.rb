module Api
  class ContactsController < BaseController
    # POST /api/contacts/bulk
    def bulk_create
      contacts_data = params[:contacts] || []
      created = []
      skipped = []

      contacts_data.each do |contact_data|
        if contact_data[:email].present?
          contact = Contact.find_or_initialize_by(email: contact_data[:email])
        else
          contact = Contact.new
        end
        if contact.new_record?
          contact.assign_attributes(
            name: contact_data[:name],
            email: contact_data[:email],
            phone: contact_data[:phone],
            role: contact_data[:role],
            source: contact_data[:source],
            confidence_score: contact_data[:confidence_score],
            company_id: contact_data[:company_id]
          )
          if contact.save
            created << { id: contact.id, email: contact.email }
          else
            skipped << { email: contact_data[:email], errors: contact.errors.full_messages }
          end
        else
          skipped << { email: contact_data[:email], reason: "already exists" }
        end
      end

      render json: { created: created.size, skipped: skipped, created_contacts: created }
    end
  end
end
