class TicketCommentsController < ApplicationController
  def create
    @ticket = MaintenanceTicket.find(params[:maintenance_ticket_id])
    @comment = @ticket.ticket_comments.build(user: current_user, body: params.dig(:ticket_comment, :body))
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to maintenance_ticket_path(@ticket), notice: "Comment added" }
      end
    else
      redirect_to maintenance_ticket_path(@ticket), alert: @comment.errors.full_messages.to_sentence
    end
  end
end
