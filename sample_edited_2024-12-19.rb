class User
  attr_reader :user_id, :email, :type

  UserType={
    "1" => "CUSTOMER",
    "2" => "EMPLOYEE"
  }

  def initialize(user_id:, email:, type:, is_email_confirmed: false)
    @user_id = user_id
    @email = email
    @type = type
    @is_email_confirmed = is_email_confirmed
  end

  def can_change_email()
      if(@is_email_confirmed)
        return "できないよ"
  end

  def change_email(company, new_email)
    assert (can_change_email == nil)
    new_type = company.is_email_corporate(new_email) ? UserType::EMPLOYEE : UserType::CUSTOMER

    if @type != new_type
      delta = new_type == UserType::EMPLOYEE ? 1 : -1
      company.change_number_of_employees(delta)
    end

    @email = new_email
    @type = new_type
  end
end

class UserFactory
  def self.create(user_data)
    User.new(
      user_id: user_data[0].to_i,
      email: user_data[1].to_s,
      type: User::UserType[user_data[2].to_s]
      )
  end
end

class UserController
  def change_email(user_id, new_email)
    user_data = Database.get_user_by_id(user_id)
    user = UserFactory.create(user_data)

    result = user.can_change_email
    if (result != nil)
      return result

    company_data = Database.get_company
    company = CompanyFactory.create(company_data)

    user.change_email(company, new_email)

    Database.save_company(company)
    Database.save_user(user)
    MessageBus.send_email_changed_message(user_id, new_email)
  end
end

class CompanyFactory
  def self.create(company_data)
    Company.new(
      company_domain_name: company_data[0].to_s,
      number_of_employees: company_data[1].to_i
    )
  end
end

class Company
  def initialize(company_domain_name:, number_of_employees:)
    @company_domain_name = company_domain_name
    @number_of_employees = number_of_employees
  end

  def is_email_corporate(new_email)
    email_domain = new_email.split('@')[1]
    email_domain == company.company_domain_name
  end

  def change_number_of_employees(delta)
    assert(@number_of_employees + delta > 0 )
    @number_of_employees += delta
  end
end
