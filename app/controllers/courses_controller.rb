class CoursesController < ApplicationController
  before_filter :authenticate_admin!, :only => [:destroy]
  before_filter :authenticate_user!, :except => [:new, :create, :summary]
  
  def index
    @courses_all = Course.all
    @courses_mine = Array.new
    @courses_all.collect {|course| course.users.include?(current_user) ? @courses_mine << course : '' }
    @repositories = Repository.find(:all, :order => :name)
  end  
  
  def show
    @course = Course.find(params[:id])
  end
  
  def new
    unless params[:repository].nil? || params[:repository].blank?
      @repository = Repository.find(params[:repository])
    end  
    @course = Course.new
    @uploader = FileUploader.new
  end
  
  def edit
    @course = Course.find(params[:id])
  end
  
  def create
    unless params[:repository_id].nil?
      @repository = Repository.find(params[:repository_id])
      params[:course][:repository_id] = params[:repository_id]
    end  
    
    unless params[:other].empty?
      params[:course][:staff_involvement] = (params[:course][:staff_involvement] << params[:other]).reject{ |e| e.empty? }.join(", ")
    else
      params[:course][:staff_involvement] = params[:course][:staff_involvement].reject{ |e| e.empty? }.join(", ")  
    end  
    params[:course][:timeframe] = DateTime.strptime(params[:course][:timeframe], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe].empty?
    params[:course][:pre_class_appt] = DateTime.strptime(params[:course][:pre_class_appt], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt].empty?
    @course = Course.new(params[:course])
    respond_to do |format|
      if (!@repository.nil?) && @course.number_of_students > @repository.class_limit
        flash[:error] = "Please enter number of students below the repository maximum."
        format.html { render action: "new" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      else  
        if @course.save
          if user_signed_in?
            format.html { redirect_to summary_course_url(@course), notice: 'Course was successfully created.' }
          else
            format.html { redirect_to summary_course_url(:id => @course.id), notice: 'Course was successfully submitted for approval.' }
          end    
        else
          format.html { render action: "new" }
          format.json { render json: @course.errors, status: :unprocessable_entity }
        end
      end  
    end
  end
  
  def update
    @course = Course.find(params[:id])

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to courses_url, notice: 'Course was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to courses_url }
      format.json { head :no_content }
    end
  end
  
  def summary
    @course = Course.find(params[:id])
  end
   
end