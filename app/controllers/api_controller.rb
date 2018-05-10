class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:authenticate]

  def index
    render json: {
        message: 'JeonSoft API is working fine.'
    }
  end

  def authenticate
    reset_session
    user_name = 'results@js!'
    password = 'j$@pi_r3$ults'

    if params[:user_name] == user_name && params[:password] == password
      render json: {authenticity_token: form_authenticity_token}
    else
      logger.fatal "Error upon authentication: user_name=#{params[:user_name]}, password=#{params[:password]}"
      render text: 'Error user name and password.'
    end
  end

  def is_numeric? string
    true if Float(string) rescue false
  end

  def payrolls
	  begin
      error_message = ''
      payrolls = Employee.find_by_sql(['SELECT DISTINCT p.PayYear, m.Name AS PayMonth, pp.Name AS PayPeriod, CONVERT(VARCHAR(12), p.PayDate, 101) AS PayDate
        FROM tblPayrolls p
          INNER JOIN tblMonths m ON m.Id = p.PayMonth
          INNER JOIN tblPayrollPeriods pp ON pp.Id = p.PayrollPeriodId
        WHERE p.PayrollTypeId = 1
          AND p.IsClosed = 1
          AND p.CompanyId = 1'])

      payrolls_json = []
      payrolls.each do |p|
        p = JSON.parse(p.to_json)
        p.delete('Id')
        payrolls_json << p
      end
    rescue => e
      error_message = e.message
      logger.fatal "Error upon checking payrolls. Error: #{e.message}"
      raise ActiveRecord::Rollback
    ensure
      if error_message == ''
        render json: {success: true, payrolls: payrolls_json}
      else
        render json: {error: error_message}
      end
    end
  end

  def payslip
    Employee.transaction do
      error_message = ''
      begin

        #Validate Employee Code
        employee_code = params['EmployeeCode'].nil? ? '' : params['EmployeeCode'].strip
        if employee_code == ''
          raise 'Employee Code is blank.'
        else
          employee = Employee.find_by_sql(['SELECT Id, CompanyId FROM tblEmployees WHERE LOWER(EmployeeCode) = LOWER(?)', employee_code])
          if employee.length <= 0
            raise 'Employee Code does not exist.'
          end
        end

        #Validate Pay Year
        pay_year = params['PayYear'].nil? ? 0 : params['PayYear'].strip
        if pay_year == 0 || pay_year == ''
          raise 'Pay Year is not specified.'
        elsif !is_numeric?(pay_year)
          raise 'Invalid Pay Year.'
        end

        #Validate Pay Month
        pay_month = params['PayMonth'].nil? ? '' : params['PayMonth'].strip
        if pay_month == ''
          raise 'Pay Month is blank.'
        else
          db_pay_month = Employee.find_by_sql(['SELECT Id FROM tblMonths WHERE LOWER(Name) = LOWER(?)', pay_month])
          if db_pay_month.length <= 0
            raise 'Invalid Pay Month.'
          end
        end

        #Validate Payroll Period
        payroll_period = params['PayrollPeriod']
        db_payroll_period = Employee.find_by_sql(['SELECT Id, Active, Name FROM tblPayrollPeriods WHERE LOWER(Name) = LOWER(?)', payroll_period])
        if db_payroll_period.length <= 0
          raise 'Invalid Payroll Period.'
        elsif !db_payroll_period[0].Active
          raise "Payroll Period '#{db_payroll_period[0].Name}' is inactive."
        end

        pay_year = pay_year.to_i
        company_id = employee[0].CompanyId
        employee_id = employee[0].Id
        pay_month = db_pay_month[0].Id
        payroll_period = db_payroll_period[0].Id

        api_user_id = Employee.find_by_sql(['SELECT Id FROM tblSecurityUsers WHERE SysCode = ?', 'API_User'])
        #Employee.find_by_sql(['EXEC uspLogUser ?, ?, 1', company_id, api_user_id]) #login api user

        Employee.find_by_sql(['
          IF EXISTS(SELECT * FROM tblSessionInformation WHERE SPID = @@SPID)
          DELETE FROM tblSessionInformation WHERE SPID = @@SPID
          INSERT INTO tblSessionInformation (SPID, CompanyId, SecurityUserId, [Date], Login)
          VALUES(@@SPID, ?, ?, dbo.fnReplaceTime(GETDATE(), 0), GETDATE())', company_id, api_user_id])

        Employee.find_by_sql(['UPDATE tblSessionInformation SET CompanyId = ?, EmployeeId = ?, PayYear = ?, PayMonth = ?, PayrollPeriodId = ?, PayrollCode = dbo.fnPayrollCode(?, ?, ?) WHERE SPID = @@SPID',
                              company_id, employee_id, pay_year, pay_month, payroll_period, pay_year, pay_month, payroll_period])

        e_payslip_info = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 1', company_id, employee_id, pay_year, pay_month, payroll_period])
        #Validate if payroll already exist
        if e_payslip_info.length <= 0
          raise "Cannot find any payroll for employee '#{employee_code}' on #{params['PayMonth']} #{params['PayrollPeriod']}, #{pay_year}. Please specify existing payroll."
        end

        gross_pay = e_payslip_info[0].GrossEarnings.to_f.round(3)
        net_pay = e_payslip_info[0].NetPay.to_f.round(3)

        e_payslip_earnings = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 2', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_other_pay = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 3', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_gov_ded = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 4', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_other_ded = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 5', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_loan_ded = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 6', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_taxable_earnings_ytd = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 7', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_non_taxable_earnings_ytd = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 8', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_gov_ded_ytd = Employee.find_by_sql(['EXEC uspCustomAPIResultsEmployeePayslip ?, ?, ?, ?, ?, 9', company_id, employee_id, pay_year, pay_month, payroll_period])
        e_payslip_remarks = Employee.find_by_sql(['SELECT ri.Remarks FROM tblCompanies c INNER JOIN tblReportItems ri ON ri.ItemId = c.PayslipId WHERE c.Id = ?', company_id])

        e_payslip_info = JSON.parse(e_payslip_info[0].to_json)
        e_payslip_info.delete('Id')

        e_payslip_earnings_json = []
        e_payslip_earnings_sub_total = 0
        e_payslip_earnings.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_earnings_sub_total += e['Amount'].to_f
          e_payslip_earnings_json << e
        end

        e_payslip_other_pay_json = []
        e_payslip_other_pay_sub_total = 0
        e_payslip_other_pay.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_other_pay_sub_total += e['Amount'].to_f
          e_payslip_other_pay_json << e
        end

        e_payslip_gov_ded_json = []
        e_payslip_gov_ded_sub_total = 0
        e_payslip_gov_ded.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_gov_ded_sub_total += e['Amount'].to_f
          e_payslip_gov_ded_json << e
        end

        e_payslip_other_ded_json = []
        e_payslip_other_ded_sub_total = 0
        e_payslip_other_ded.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_other_ded_sub_total += e['Amount'].to_f
          e_payslip_other_ded_json << e
        end

        e_payslip_loan_ded_json = []
        e_payslip_loan_amount_sub_total = 0
        e_payslip_loan_amortization_sub_total = 0
        e_payslip_loan_balance_sub_total = 0
        e_payslip_loan_ded.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_loan_amount_sub_total += e['LoanAmount'].to_f
          e_payslip_loan_amortization_sub_total += e['Amortization'].to_f
          e_payslip_loan_balance_sub_total += e['Balance'].to_f
          e_payslip_loan_ded_json << e
        end

        e_payslip_taxable_earnings_ytd_json = []
        e_payslip_taxable_earnings_ytd_sub_total = 0
        e_payslip_taxable_earnings_ytd.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_taxable_earnings_ytd_sub_total += e['YTDAmount'].to_f
          e_payslip_taxable_earnings_ytd_json << e
        end

        e_payslip_non_taxable_earnings_ytd_json = []
        e_payslip_non_taxable_earnings_ytd_sub_total = 0
        e_payslip_non_taxable_earnings_ytd.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_non_taxable_earnings_ytd_sub_total += e['YTDAmount'].to_f
          e_payslip_non_taxable_earnings_ytd_json << e
        end

        e_payslip_gov_ded_ytd_json = []
        e_payslip_gov_ded_ytd_sub_total = 0
        e_payslip_gov_ded_ytd.each do |e|
          e = JSON.parse(e.to_json)
          e.delete('Id')
          e_payslip_gov_ded_ytd_sub_total += e['YTDAmount'].to_f
          e_payslip_gov_ded_ytd_json << e
        end

      rescue => e
        error_message = e.message
        logger.fatal "Error upon viewing payslip: employee=#{employee_code}, pay_year=#{pay_year}, pay_month=#{pay_month}, payroll_period=#{payroll_period} error: #{e.message}"
        raise ActiveRecord::Rollback
      ensure
        reset_session
        #Employee.find_by_sql(['EXEC uspLogUser ?, ?, 0', company_id, api_user_id]) #logout api user
        if error_message == ''
          render json: {success: true,
                        e_payslip: [
                            basic_info: e_payslip_info,
                            earnings: e_payslip_earnings_json, earnings_sub_total: e_payslip_earnings_sub_total.round(3),
                            other_pay: e_payslip_other_pay_json, other_pay_sub_total: e_payslip_other_pay_sub_total.round(3),
                            gross_pay: gross_pay,
                            government_deductions: e_payslip_gov_ded_json, government_deductions_sub_total: e_payslip_gov_ded_sub_total.round(3),
                            other_deductions: e_payslip_other_ded_json, other_deductions_sub_total: e_payslip_other_ded_sub_total.round(3),
                            loan_deductions: e_payslip_loan_ded_json, loan_amount_sub_total: e_payslip_loan_amount_sub_total.round(3),
                            loan_amortization_sub_total: e_payslip_loan_amortization_sub_total.round(3), loan_balance_sub_total: e_payslip_loan_balance_sub_total.round(3),
                            net_pay: net_pay,
                            ytd_taxable_earnings: e_payslip_taxable_earnings_ytd_json, ytd_taxable_earnings_sub_total: e_payslip_taxable_earnings_ytd_sub_total.round(3),
                            ytd_non_taxable_earnings: e_payslip_non_taxable_earnings_ytd_json, ytd_non_taxable_earnings_sub_total: e_payslip_non_taxable_earnings_ytd_sub_total.round(3),
                            ytd_government_deductions: e_payslip_gov_ded_ytd_json, ytd_government_deductions_sub_total: e_payslip_gov_ded_ytd_sub_total.round(3),
                            remarks: e_payslip_remarks[0].Remarks
                        ]
          }
        else
          render json: {error: error_message}
        end
      end
    end
  end
end
