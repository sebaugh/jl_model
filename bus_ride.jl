# loading necessary libraries
using Random, Distributions, Statistics, DataFrames

function new_paid_free_passengers(n_passengers::Int, p_freerider::Float64)
    """Function that calculates how many of new passengers are freeriders and how many paid for the ride
    
    Arguments:
    - n_passengers::Int - number of new passengers that enter the bus
    - p_freerider::Float64 - between 0 and 1, probability of a random new passenger being a freerider

    Returns:
    - A named tuple containing:
        - new_freerider::Int - number of new freeriders
        - new_paid::Int - number of new passengers who paid for the ride
    """

    @assert (0 <= p_freerider) && (p_freerider <= 1) "freerider probability outside range"

    # Initialize counters for paid and freeriders
    paid = 0
    n_freerider = 0

    # Simulating passengers
    for passenger in 1:n_passengers
        if rand() <= p_freerider
            n_freerider += 1
        else
            paid += 1
        end
    end

    return (new_freerider = n_freerider, new_paid = paid)
end


function bus_ride(;
    n_stops = 7,
    max_pass = 60,
    avg_bus = 10,
    n_passengers = 15,
    n_control = true,
    stop_cost,
    ticket_price = 0,
    pass_cost = 3.5,
    p_control = 0.05,
    ticket_penalty = 20,
    control_cost = 50,
    controlled = false)
    """Function simulating a single bus ride 
    there are no mandatory bus stops there is a maksimum number of stops but the bus will not stop at all of them, 
    the number of stops defines the length of the ride and with the cost of a single stop its total cost,
    the ticket control can occur only once during the whole trip,
    at each bus stop there is a random number of new passengers,
    probability of being a freerider is constant for the whole ride.
    
    Arguments:
    - n_stops::Int - number of all possible stops for the bus
    - max_pass::Int - maximum capacity of the bus for the passengers
    - avg_bus::Int - mean number of passengers exiting and entering the bus at a single stop
    - n_passengers::Int - mean number of passengers that enter the bus in the beginning of the trip
    - n_control::Bool - variable saying if there is available ticket controler
    - stop_cost::Float64 - cost of driving the distance of a single stop
    - ticket_price::Float64 - price that a passenger pays for a ticket
    - pass_cost::Float64 - cost of an additional passenger
    - p_control::Float64 - probability of a ticket control at a stop under the condition that one is available
    - ticket_penalty::Float64 - the fee that a single freerider pays in case he gets caught during ticket control
    - control_cost::Float64 - the cost of a single ticket control

    Returns a tuple containing:
        - bus_revenue::Float64 - a revenue of the bus trip
        - controlled::Bool - a variable saying if there was a ticket control during the ride
    """

    @assert pass_cost <= ticket_price
    n_passengers = rand(max((n_passengers - 4), 0):(n_passengers + 4))
    n_passengers = min(n_passengers, max_pass)
    
    control_ability = max_pass/3

    bus_revenue = 0.0
    tot_freeriders = 0
    n_freerider = 0
    paid = 0
    bus_penalty = 0

    p_freerider = ticket_price/(ticket_price + ticket_penalty^2)

    # addin
    new_passengers = new_paid_free_passengers(n_passengers, p_freerider)
    n_freerider += new_passengers.new_freerider
    tot_freeriders += new_passengers.new_freerider
    paid += new_passengers.new_paid


    pois = Distributions.Poisson(avg_bus)
    for stop in 1:n_stops
        if rand() <= 0.6 # check if bus stops at a stop
            pass_exit = rand(pois)
            pass_exit = min(pass_exit, n_passengers)
            n_freerider -= rand(0:pass_exit)
            
            n_passengers -= pass_exit # updating number of passengers
            @assert n_passengers >= 0
            n_freerider = max(n_freerider, 0)
            n_freerider = min(n_freerider, n_passengers)

            pass_new = rand(pois)
            available_seats = max_pass - n_passengers
            pass_new = min(pass_new, available_seats) 
            n_passengers += pass_new # updating number of passengers
            @assert (n_passengers >= 0 && n_passengers <= max_pass)

            new_passengers = new_paid_free_passengers(n_passengers, p_freerider)
            n_freerider += new_passengers.new_freerider
            tot_freeriders += new_passengers.new_freerider
            paid += new_passengers.new_paid

            if ((controlled == false) & (n_control > 0) & (rand() <= p_control))
                if n_passengers <= control_ability
                    bus_penalty = n_freerider * ticket_penalty
                else 
                    if n_freerider > 0
                        for freerider in 1:n_freerider
                            if rand() <= 1 - n_passengers/max_pass
                                bus_penalty += ticket_penalty
                            end
                        end
                    end
                end
                controlled = true
                n_control -= 1
            end
        end
    end
    bus_revenue = paid * (ticket_price - pass_cost) + bus_penalty - n_stops * stop_cost - tot_freeriders * pass_cost - controlled * control_cost
    (; bus_revenue, n_control)
end

bus_ride(n_control = 10, stop_cost = 0, avg_bus = 0, n_passengers = 0, max_pass = 0, ticket_price = 0, pass_cost = 0)