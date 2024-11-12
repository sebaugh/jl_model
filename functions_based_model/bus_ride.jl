# loading necessary libraries
using Random, Distributions, Statistics, DataFrames

function new_paid_free(pass_new::Int, p_freerider::Float64)
    """Function that calculates how many of new passengers are freeriders and how many paid for the ride
    
    Arguments:
    - pass_new::Int - number of new passengers that enter the bus
    - p_freerider::Float64 - between 0 and 1, probability of a random new passenger being a freerider

    Returns:
    - A named tuple containing:
        - new_freerider::Int - number of new freeriders
        - new_paid::Int - number of new passengers who paid for the ride
    """

    @assert (0 <= p_freerider) && (p_freerider <= 1) "freerider probability outside range"

    # Initialize counters for paid and freeriders
    new_paid = 0
    new_freerider = 0

    # Simulating passengers
    for passenger in 1:pass_new
        if rand() <= p_freerider
            new_freerider += 1
        else
            new_paid += 1
        end
    end

    return (; new_freerider, new_paid)
end


function bus_ride(;
    n_stops = 7,
    max_pass = 60,
    avg_bus = 10,
    n_passengers = 15,
    control_available = true,
    stop_cost = 10,
    ticket_price = 7,
    pass_cost = 3.5,
    p_control = 0.5,
    ticket_penalty = 20,
    control_cost = 50)
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
    - control_availabe::Bool - variable saying if there is available ticket controler
    - stop_cost::Float64 - cost of driving the distance of a single stop
    - ticket_price::Float64 - price that a passenger pays for a ticket
    - pass_cost::Float64 - cost of an additional passenger
    - p_control::Float64 - probability of a ticket control for the whole ride, based on it the probability of a control at a stop is calculated
    - ticket_penalty::Float64 - the fee that a single freerider pays in case he gets caught during ticket control
    - control_cost::Float64 - the cost of a single ticket control for the city

    Returns a tuple containing:
        - bus_revenue::Float64 - a revenue of the bus trip
        - controlled::Bool - a variable saying if there was a ticket control during the ride
    """

     @assert pass_cost <= ticket_price
    
    #setting up variables
    bus_revenue = 0.0
    tot_freeriders = 0
    n_freerider = 0
    paid = 0
    bus_penalty = 0
    controlled = false

    # setting up the probability of a freerider for the ride
    p_freerider = ticket_price/(ticket_price + sqrt(ticket_penalty))
    control_ability = max_pass/3
    p_control_per_stop = 1 - (1 - p_control)^(1 / n_stops)


    # adding passengers at the start of the ride
    n_passengers = rand(max((n_passengers - 4), 0):(n_passengers + 4))
    n_passengers = min(n_passengers, max_pass)

    # adding new paid and freeriders
    new_passengers = new_paid_free(n_passengers, p_freerider)
    n_freerider += new_passengers.new_freerider
    tot_freeriders += new_passengers.new_freerider
    paid += new_passengers.new_paid


    pois = Distributions.Poisson(avg_bus)
    for stop in 1:n_stops

        # checking if the bus stops 
        if rand() <= 0.6 

            # passengers and freeriders leaving the bus
            pass_exit = rand(pois)
            pass_exit = min(pass_exit, n_passengers)
            n_freerider -= rand(0:pass_exit)
            
            # updating number of passengers
            n_passengers -= pass_exit 

            n_freerider = max(n_freerider, 0)
            n_freerider = min(n_freerider, n_passengers)

            #number of new passengers
            pass_new = rand(pois)
            available_seats = max_pass - n_passengers
            pass_new = min(pass_new, available_seats) 

            # updating number of passengers on the bus
            n_passengers += pass_new 
            @assert (n_passengers >= 0 && n_passengers <= max_pass)

            # adding paid passengers and freeriders
            new_passengers = new_paid_free(pass_new, p_freerider)
            n_freerider += new_passengers.new_freerider
            tot_freeriders += new_passengers.new_freerider
            paid += new_passengers.new_paid

            # simulating ticket control
            if ((controlled == false) & control_available == true & (rand() <= p_control_per_stop))
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
            end
        end
    end

    #calculating total revenue
    bus_revenue = paid * (ticket_price - pass_cost) + bus_penalty - n_stops * stop_cost - tot_freeriders * pass_cost - controlled * control_cost
    (; bus_revenue, controlled)
end