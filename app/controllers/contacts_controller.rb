class ContactsController < ApplicationController
  def show
    @contact = Contact.find(params[:id])
    @threads = @contact.email_threads.includes(:messages).order(created_at: :asc)
    @drafts = @contact.drafts.order(created_at: :asc)
    @followups = @contact.followups.order(sequence_number: :asc)
    @meetings = @contact.meetings.order(scheduled_at: :desc)
    @timeline = build_timeline

    # Activity & comments for right panel
    @activities = Activity.where(trackable: @contact)
                          .or(Activity.where(trackable_type: "Company", trackable_id: @contact.company_id))
                          .order(created_at: :desc)
                          .includes(:user)
                          .limit(50)
    @comments = @contact.comments.includes(:user).order(created_at: :asc)
  end

  def new
    @company = Company.find(params[:company_id])
    @contact = @company.contacts.new
  end

  def create
    @company = Company.find(params[:company_id])
    @contact = @company.contacts.new(contact_params)
    if @contact.save
      ActivityTracker.track(@contact, action: "contact_created", user: current_user, metadata: {
        name: @contact.name, email: @contact.email, phone: @contact.phone
      })
      redirect_to @contact, notice: "Contact created. Draft email task queued."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @contact = Contact.find(params[:id])
  end

  def update
    @contact = Contact.find(params[:id])
    if @contact.update(contact_params)
      redirect_to @contact, notice: "Contact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reply
    @contact = Contact.find(params[:id])
    @thread = @contact.email_threads.find(params[:thread_id])
    @messages = @thread.messages.order(created_at: :asc)
    @draft = Draft.new(
      contact: @contact,
      email_thread: @thread,
      subject: "Re: #{@thread.messages.order(:created_at).first&.subject}"
    )
  end

  private

  def build_timeline
    items = []
    @drafts.each { |d| items << { type: :draft, record: d, at: d.created_at } }
    @threads.each do |t|
      t.messages.each { |m| items << { type: :message, record: m, at: m.created_at } }
    end
    items.sort_by { |i| i[:at] }
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone, :role, :source, :confidence_score)
  end
end
