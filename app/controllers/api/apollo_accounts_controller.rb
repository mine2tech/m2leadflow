module Api
  class ApolloAccountsController < BaseController
    # GET /api/apollo/available
    def available
      account = ApolloAccount.available.first
      if account
        render json: {
          id: account.id,
          email: account.email,
          credits_remaining: account.credits_remaining,
          credentials: account.credentials_encrypted
        }
      else
        render json: { error: "No active Apollo accounts" }, status: :not_found
      end
    end

    # POST /api/apollo/usage
    def update_usage
      account = ApolloAccount.find(params[:id])
      account.update!(
        credits_remaining: params[:credits_remaining],
        status: params[:credits_remaining].to_i <= 0 ? :exhausted : :active
      )
      render json: { status: "updated" }
    end
  end
end
