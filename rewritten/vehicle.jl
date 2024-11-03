# loading necessary libraries
using Random, Distributions, Statistics, DataFrames

# define structure of vehicles
mutable struct Vehicle
    id::Int # identifier for the vehicle
    n_stops::Int # number of stops on that vehicle route
    max_pass::Int # maximum capacity of the vehicle
    avg_enter_exit::Int # average number of passengers entering and exiting the vehicle on a stop
    avg_passengers_beginning::Int # average number of passengers at the beginning of the ride
    passengers_inside::Int # number of the passengers inside the vehicle
    freeriders_inside::Int # number of freeriders inside the vehicle
    control_ability::Int # number of passengers that can be controlled without issue
    stop_cost::Float16 # cost of driving the length of a single stop
    p_control_per_stop::Float64 # probability of ticket control for a single stop
end

#define financial structure
mutable struct Financial
    ticket_price::Float16 # price of the ride
    ticket_penalty::Float16
    passenger_cost::Float16
    control_cost::Float16
    n_control_available::Int
    p_freerider::Float32 # probability of passenger being a freerider
    day_revenue::Float16 # revenue for the day
end

#function for creating vehicles
function create_vehicle(id::Int, n_stops::Int, max_pass::Int, avg_enter_exit::Int, avg_passengers_beginning::Int, stop_cost::Float16, p_control::Float64)
    """
    Function that creates a vehicle instance.

    Arguments:
    - id::Int # identifier for the vehicle
    - n_stops::Int # number of stops on that vehicle route
    - max_pass::Int # maximum capacity of the vehicle
    - avg_enter_exit::Int # average number of passengers entering and exiting the vehicle on a stop
    - avg_passengers_beginning::Int # average number of passengers at the beginning of the ride
    - stop_cost::Float16 # cost of driving the length of a single stop
    - p_control::Float64 # probability of ticket control on the whole route

    Returns:
    - Vehicle 
    """
    return Vehicle(
        id=id,
        n_stops=n_stops,
        max_pass=max_pass,
        avg_enter_exit=avg_enter_exit,
        avg_passengers_beginning=avg_passengers_beginning,
        passengers_inside=0,   # początkowa liczba pasażerów
        freeriders_inside=0,   # początkowa liczba gapowiczów
        control_ability = round(Int, max_pass / 3),
        stop_cost=Float16(stop_cost),
        p_control_per_stop= 1 - (1 - p_control)^(1 / n_stops),
    )
end

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
end

# method for simulating a ticket control
function ticket_control!(vehicle::Vehicle, financial::Financial)
    """
    Function that takes as arguments vehicle and financial data and simulates if there is a ticket control with the control itself. It updates the number of freeriders and day_revenue.

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

    # check if control is available and determine if control happens
    if (financial.n_control_available > 0 && (rand() <= vehicle.p_control_per_stop))
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
end
