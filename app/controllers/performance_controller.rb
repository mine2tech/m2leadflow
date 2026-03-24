class PerformanceController < ApplicationController
  def index
    @period = params[:period] || "week"
    @range = case @period
             when "day" then 1.day.ago..Time.current
             when "week" then 1.week.ago..Time.current
             when "month" then 1.month.ago..Time.current
             when "all" then Time.at(0)..Time.current
             else 1.week.ago..Time.current
             end

    @emails_sent = Message.where(direction: :outbound, created_at: @range).count
    @replies_received = Message.where(direction: :inbound, created_at: @range).count
    @reply_rate = @emails_sent > 0 ? ((@replies_received.to_f / @emails_sent) * 100).round(1) : 0
    @meetings_booked = Meeting.where(created_at: @range).count
    @drafts_created = Draft.where(created_at: @range).count
    @drafts_reviewed = Activity.where(action: "draft_reviewed", created_at: @range).count

    @classification_counts = Message.where(direction: :inbound, created_at: @range)
                                     .where.not(classification: nil)
                                     .group(:classification).count

    @daily_stats = build_daily_stats
    @user_stats = build_user_stats
  end

  private

  def build_daily_stats
    days = case @period
           when "day" then 1
           when "week" then 7
           when "month" then 30
           else 30
           end

    sent_by_day = Message.where(direction: :outbound, created_at: days.days.ago..Time.current)
                         .group("DATE(created_at)").count
    replies_by_day = Message.where(direction: :inbound, created_at: days.days.ago..Time.current)
                            .group("DATE(created_at)").count
    meetings_by_day = Meeting.where(created_at: days.days.ago..Time.current)
                             .group("DATE(created_at)").count

    (0...days).map do |i|
      date = i.days.ago.to_date
      {
        date: date,
        sent: sent_by_day[date] || 0,
        replies: replies_by_day[date] || 0,
        meetings: meetings_by_day[date] || 0
      }
    end.reverse
  end

  def build_user_stats
    User.all.filter_map do |user|
      sent = Activity.where(action: "email_sent", user: user, created_at: @range).count
      reviewed = Activity.where(action: "draft_reviewed", user: user, created_at: @range).count
      next if sent == 0 && reviewed == 0

      { user: user, emails_sent: sent, drafts_reviewed: reviewed }
    end
  end
end
