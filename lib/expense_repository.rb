include ExpensesHelper

class ExpenseRepository

  attr_reader :user

  def initialize user=nil
    @user = user
  end

  def expenses
    Expense.where(:user_id => user.id)
  end

  def expenses_by_year_and_month params
    date = params[:date]
    start_date, end_date = start_and_end_of_month(date)
    expenses.between(start_date, end_date)
  end

  def expenses_by_year_and_month_weekly params
    date = params[:date]
    start_date, end_date = start_and_end_of_month(date)
    expenses.between(start_date, end_date).for_budget.select {
      |e| Week.new(e.date).month == date.month
    }.group_by {
      |e| e.date.strftime("%U").to_i
    }
  end

  def weekly_balance params
    expenses_by_year_and_month_weekly(params).inject(Hash.new) { |hash, pair| hash[pair[0]] = pair[1].sum(&:amount); hash }
  end

  def total_for_month params
    expenses_by_year_and_month(params).sum(&:amount)
  end

  def daily_average_for_month params
    date = params[:date]
    total = total_for_month params
    days_passed = (date.is_in_current_month ? Date.today.day : date.end_of_month.day)
    total.to_f / days_passed
  end

  def expenses_by_year_month_and_category params
    date = params[:date]
    category_name = params[:category_name]
    expenses_by_year_and_month(:date => date).select { |e| e.category.name == category_name }
  end

  def total_for_day params
    date = params[:date]
    expenses.where(:date => date).sum(&:amount)
  end

  def amounts_by_date_for_month(params)
    date = params[:date]
    start_date, end_date = start_and_end_of_month(date)
    user_expenses = expenses.between(start_date, end_date)
    daily_expenses = ""
    start_date.upto(end_date) do |date|
      daily_expenses += (-1 * user_expenses.select {|e| e.date == date }.sum(&:amount)).to_s + ","
    end
    return daily_expenses.gsub(/,$/, "")
  end

end
