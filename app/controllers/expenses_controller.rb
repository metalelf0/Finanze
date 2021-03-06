class ExpensesController < ApplicationController

  before_filter do
    redirect_to :login unless current_user
  end

  def index
    if current_user
      @date = build_date_from_params(params)
      @categories = current_user.categories
      if params[:category_name].blank?
        @expenses = current_user.expenses_by_year_and_month(:date => @date).sort { |e1, e2| e1.date <=> e2.date }.select {|e| e.amount < 0}
        @incomes =  current_user.expenses_by_year_and_month(:date => @date).sort { |e1, e2| e1.date <=> e2.date }.select {|e| e.amount >= 0}
      else
        @expenses = current_user.expenses_by_year_month_and_category(:date => @date, :category_name => params[:category_name]).sort { |e1, e2| e1.date <=> e2.date }
      end
      @categories_cloud_chart = CategoriesCloudChart.new(:user => current_user, :date => @date)
      @categories_pie_chart = CategoriesPieChart.new(:user => current_user, :date => @date)
      @expenses_daily_chart = ExpensesDailyChart.new(:user => current_user, :date => @date)
    else
      redirect_to login_url
    end
  end

  def show
    @expense = Expense.find(params[:id])
  end

  def new
    @expense = Expense.new
  end

  def edit
    @expense = Expense.find(params[:id])
    @categories = current_user.categories
  end

  def create
    @expense = Expense.new(params[:expense])
    if @expense.save
      flash[:notice] = 'Expense was successfully created.'
      redirect_to expenses_url
    else
      render :action => "new"
    end
  end

  def create_many
    @page_title = "Create many movements"
    for i in 1..10 do
      if !(params["elem" + i.to_s]["amount"].blank? || params["elem" + i.to_s]["description"].blank?)
        expense = Expense.new
        # TODO: "elem" a costante
        params["elem" + i.to_s] = handle_multiedit_params(params["elem" + i.to_s])
        expense.attributes = expense.attributes.merge(params["elem" + i.to_s]).merge(:user_id => current_user.id)
        expense.save
      end
    end
    flash[:notice] = "expenses correctly saved"
    redirect_to expenses_url
  end

  def recurring
    if request.post?
      recurring_expense_params = recurring_expense_params_from params[:recurring_expense]
      RecurringExpense.new(recurring_expense_params).create_items
      flash[:notice] = "recurring expenses correctly created"
      redirect_to expenses_url
    else
      @page_title = "Create recurring expenses"
      @recurring_expense = RecurringExpense.new(user: current_user)
      @categories = current_user.categories
    end
  end

  def recurring_expense_params_from parameters
    parameters.merge(
      user: current_user,
      start_date: date_from_string(parameters[:start_date]),
      end_date: date_from_string(parameters[:end_date]),
      day_of_month: parameters[:day_of_month].to_i,
      amount: parameters[:amount].to_f
    )
  end

  def date_from_string string
    string ? Date.parse(string) : nil
  end

  def update
    @expense = Expense.find(params[:id])
    if @expense.update_attributes(params[:expense])
      flash[:notice] = 'Expense was successfully updated.'
      redirect_to expenses_url
    else
      render :action => "edit"
    end
  end

  def destroy
    @expense = Expense.find(params[:id])
    @expense.destroy
    redirect_to(expenses_url)
  end

  def handle_multiedit_params params
    params["amount"] = "#{params["sign"]}#{params["amount"].sub("," , ".")}"
    params["description"] = params["description"].capitalize
    params.delete("sign")
    return params
  end

  private

  def build_date_from_params params
    if not (params[:year].nil? or params[:month].nil?)
      @date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    else
      @date = Date.today
    end
  end

end
