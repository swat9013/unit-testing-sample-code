class User
  attr_reader :user_id, :email, :type

  module UserType
    CUSTOMER = 1
    EMPLOYEE = 2
  end

  def change_email(user_id, new_email)
    data = Database.get_user_by_id(user_id)
    @user_id = user_id
    @email = data[1]
    @type = data[2]

    return if @email == new_email

    company_data = Database.get_company
    company_domain_name = company_data[0]
    number_of_employees = company_data[1]

    email_domain = new_email.split('@')[1]
    is_email_corporate = email_domain == company_domain_name
    new_type = is_email_corporate ? UserType::EMPLOYEE : UserType::CUSTOMER

    if @type != new_type
      delta = new_type == UserType::EMPLOYEE ? 1 : -1
      new_number = number_of_employees + delta
      Database.save_company(new_number)
    end

    @email = new_email
    @type = new_type

    Database.save_user(self)
    MessageBus.send_email_changed_message(user_id, new_email)
  end
end
