class FileStatsController < ApplicationController
  include FileStatsHelper

  before_action :set_file_stat, only: [:show, :edit, :update, :destroy, :pause, :unpause, :cancel]

  def pause
    @file_stat = FileStat.find(params[:id])
    helpers.pause_job(@file_stat.job_id)
    redirect_back(fallback_location: root_path)
  end

  def unpause
    @file_stat = FileStat.find(params[:id])
    helpers.unpause_job(@file_stat.job_id)
    redirect_back(fallback_location: root_path)
  end

  def cancel
    @file_stat = FileStat.find(params[:id])
    helpers.cancel_job(@file_stat.job_id)
    redirect_back(fallback_location: root_path)
  end

  # GET /file_stats
  # GET /file_stats.json
  def index
    @file_stats = FileStat.all
  end

  # GET /file_stats/1
  # GET /file_stats/1.json
  def show
  end

  # GET /file_stats/new
  def new
    @file_stat = FileStat.new
  end

  # GET /file_stats/1/edit
  def edit
  end

  # POST /file_stats
  # POST /file_stats.json
  def create
    @file_stat = FileStat.new(file_stat_params)
    
    logger.debug(file_stat_params)

    respond_to do |format|
      if @file_stat.save

        logger.debug("Starting sidekiq process for file #{@file_stat.filename} database id #{@file_stat.id}")
        jid = FileStatsWorker.perform_async(@file_stat.filename, @file_stat._id.to_s()) 
        
        @file_stat.job_id = jid
        @file_stat.save

        format.html { redirect_to @file_stat, notice: 'File stat was successfully created.' }
        format.json { render :show, status: :created, location: @file_stat }
      else
        format.html { render :new }
        format.json { render json: @file_stat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /file_stats/1
  # PATCH/PUT /file_stats/1.json
  def update
    respond_to do |format|
      if @file_stat.update(file_stat_params)
        format.html { redirect_to @file_stat, notice: 'File stat was successfully updated.' }
        format.json { render :show, status: :ok, location: @file_stat }
      else
        format.html { render :edit }
        format.json { render json: @file_stat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /file_stats/1
  # DELETE /file_stats/1.json
  def destroy
    if @file_stat.status != 'Finished'
      delete_job(@file_stat.job_id)
    end
    # 
    delete_results(@file_stat._id.to_s())

    @file_stat.destroy
    respond_to do |format|
      format.html { redirect_to file_stats_url, notice: 'File stat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_file_stat
      @file_stat = FileStat.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def file_stat_params
      params.require(:file_stat).permit(:username, :filename, :job_id, :status, :status_message, :progress)
    end

end
