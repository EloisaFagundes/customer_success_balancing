require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  def filter_css
    @customer_success_away.each do |cs|
      @customer_success.delete_if { |x| x[:id] == cs }
    end
  end

  def find_cs(customer)
    filter_css
    condition = { has_difference: 0, find_id_cs: 0 }
    @customer_success.each { |cs|
      difference = cs[:score] - customer[:score]
      verify = condition[:find_id_cs] == 0 || difference < condition[:has_difference]
      condition = { has_difference: difference, find_id_cs: cs[:id] } if difference >= 0 && verify
    }
    condition[:find_id_cs]
  end

  def cs_and_client_list
    @customers.map { |customer| { customer_id: customer[:id], cs_id: find_cs(customer) } }
  end

  def winner(list)
    condition = { has_total_customers: 0, winner_id_cs: 0 }
    @customer_success.each do |cs|
      total_customers = list.select { |item| item[:cs_id] == cs[:id] }.length
      if total_customers > condition[:has_total_customers]
        condition = { has_total_customers: total_customers, winner_id_cs: cs[:id] }
      elsif total_customers == condition[:has_total_customers] && total_customers.positive?
        condition = { has_total_customers: total_customers, winner_id_cs: 0 }
      end
    end
    condition[:winner_id_cs]
  end

  # Returns the id of the CustomerSuccess with the most customers
  def execute
    # Write your solution here
    list = cs_and_client_list
    winner(list)
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    css = [{ id: 1, score: 60 }, { id: 2, score: 20 }, { id: 3, score: 95 },{ id: 4, score: 75 }]
    customers = [{ id: 1, score: 90 }, { id: 2, score: 20 }, { id: 3, score: 70 }, { id: 4, score: 40 }, { id: 5, score: 60 },{ id: 6, score: 10 }]

    balancer = CustomerSuccessBalancing.new(css, customers, [2, 4])
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    css = array_to_map([11, 21, 31, 3, 4, 5])
    customers = array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60])
    balancer = CustomerSuccessBalancing.new(css, customers, [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    customer_success = Array.new(1000, 0)
    customer_success[998] = 100

    customers = Array.new(10_000, 10)

    balancer = CustomerSuccessBalancing.new(array_to_map(customer_success), array_to_map(customers), [1000])

    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 999, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(array_to_map([1, 2, 3, 4, 5, 6]),
                                            array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 2, 3, 3, 4, 5]),
                                            array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal balancer.execute, 1
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]),
                                            array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [1, 3, 2])
    assert_equal balancer.execute, 0
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]),
                                            array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [4, 5, 6])
    assert_equal balancer.execute, 3
  end

  def array_to_map(arr)
    out = []
    arr.each_with_index { |score, index| out.push({ id: index + 1, score: score }) }
    out
  end
end

Minitest.run
