module RideFunctionsModule

include("structures_module.jl")

using .StructuresModule

# method for simulating the beginning the ride of the vehicle
function initialize_ride!(vehicle::Vehicle, financial::Financial, pois = Distributions.Poisson(vehicle.avg_passengers_beginning))
    """
    Function that takes the vehicle, financial data, and distribution of number of passengers and initializes the values for the specific vehicle ride including the initial number of passengers, freeriders, probability of a ticket control at a stop.

    Arguments:
    - `vehicle::Vehicle` - The vehicle state data.
    - `financial::Financial` - Financial data for the ride.
    - `pois` - specific Poisson distribution with average equal to the average number of passengers at the start of the ride

    Modifies:
    - `vehicle.passengers_inside`
    - `vehicle.freeriders_inside`
    - `financial.day_revenue`
    """

    # set up the probability of ticket control per stop and control control_ability
    financial.day_revenue -= vehicle.n_stops * vehicle.stop_cost
    
    # new passengers embark the vehicle
    new_passengers = rand(pois)
    vehicle.passengers_inside = min(new_passengers, vehicle.max_pass)
    financial.day_revenue -= vehicle.passengers_inside * financial.passenger_cost

    # checking which new passengers are freeriders
    vehicle.freeriders_inside = 0

    for _ in 1:vehicle.passengers_inside
        if rand() <= vehicle.p_freerider
            vehicle.freeriders_inside += 1
        else
            financial.day_revenue += financial.ticket_price
        end
    end
    @assert (vehicle.freeriders_inside >= 0 && vehicle.freeriders_inside <= vehicle.passengers_inside)    

end

# method for simulating a vehicle stop with passengers departing and new embarking
function vehicle_stop!(vehicle::Vehicle, financial::Financial, pois = Distributions.Poisson(vehicle.avg_enter_exit))
    """
    Function that takes the vehicle, financial data, and distribution of number of passengers and simulates a vehicle stop, with passengers (including freeriders) leaving and entering the vehicle.

    Arguments:
    - `vehicle::Vehicle` - The vehicle state data.
    - `financial::Financial` - Financial data for the ride.
    - `pois` - specific Poisson distribution with average equal to the average number of passengers at a stop

    Modifies:
    - `vehicle.passengers_inside`
    - `vehicle.freeriders_inside`
    - `financial.day_revenue`
    """

    # passengers leave the vehicle
    exiting_passengers = rand(pois)
    exiting_passengers = min(vehicle.passengers_inside, exiting_passengers)
    vehicle.passengers_inside -= exiting_passengers
    @assert (vehicle.passengers_inside >= 0 && vehicle.passengers_inside <= vehicle.max_pass)

    # freeriders leave the vehicle
    freeriders_leaving = rand(0:exiting_passengers)
    freeriders_leaving = min(vehicle.freeriders_inside, freeriders_leaving)
    vehicle.freeriders_inside -= freeriders_leaving
    @assert (vehicle.freeriders_inside >= 0 && vehicle.freeriders_inside <= vehicle.passengers_inside)

    # new passengers embark the vehicle
    new_passengers = rand(pois)
    new_passengers = min(new_passengers, vehicle.max_pass - vehicle.passengers_inside)
    vehicle.passengers_inside += new_passengers
    financial.day_revenue -= new_passengers*financial.passenger_cost
    @assert (vehicle.passengers_inside >= 0 && vehicle.passengers_inside <= vehicle.max_pass)

    # check which new passengers are freeriders
    for _ in 1:new_passengers
        if rand() <= vehicle.p_freerider
            vehicle.freeriders_inside += 1
        else
            financial.day_revenue += financial.ticket_price
        end
    end
    @assert (vehicle.freeriders_inside >= 0 && vehicle.freeriders_inside <= vehicle.passengers_inside)

     # check if control is available and determine if control happens
    if (financial.n_control_available > 0 && (rand() <= vehicle.p_control_per_stop))
        ticket_control!(vehicle, financial)
    end
end

# method for simulating a ticket control
function ticket_control!(vehicle::Vehicle, financial::Financial)
    """
    Function that takes as arguments vehicle and financial data and simulates a ticket control. It updates the number of freeriders and day_revenue.

    Arguments:
    - `vehicle::Vehicle` - The vehicle state data.
    - `financial::Financial` - Financial data for the ride.

    Modifies:
    - `vehicle.p_control_per_stop`
    - `vehicle.freeriders_inside`
    - `financial.day_revenue`
    - `financial.n_control_available`
    """

    # initialize penalty
    ride_penalty = 0

    if vehicle.passengers_inside <= vehicle.control_ability
        # if passenger count is within control capacity, all freeriders are caught
        ride_penalty = vehicle.freeriders_inside * financial.ticket_penalty
        vehicle.freeriders_inside = 0 # reset caught freeriders (we assume, the penalty is a ticket for the ride as well)
    else 
        # if passenger count is not within control capacity, a fraction of freeriders is caught
        caught_freeriders = 0
        for _ in 1:vehicle.freeriders_inside
            if rand() <= 1 - vehicle.passengers_inside/vehicle.max_pass
                caught_freeriders += 1
            end
        end
        # calculate the ride_penalty and update the number of freeriders
        ride_penalty = caught_freeriders * financial.ticket_penalty
        vehicle.freeriders_inside -= caught_freeriders
    end
    # update revenue and available ticket controls
    financial.day_revenue += ride_penalty - financial.control_cost
    financial.n_control_available -= 1
end


# function for simulating a full ride
function ride!(vehicle::Vehicle, financial::Financial)
    initialize_ride!(vehicle, financial)
    for _ in 1:vehicle.n_stops
        if rand() <= 0.6
            vehicle_stop!(vehicle, financial)
        end
    end
    vehicle.rides_left -= 1
end

#ending the module
end