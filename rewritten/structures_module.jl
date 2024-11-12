module StructuresModule

# loading necessary libraries
using Random, Distributions, Statistics, DataFrames

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
    rides_left::Int # number of rides for the day for the vehicle
end

#function for creating vehicles
function create_vehicle(;id::Int, n_stops::Int, max_pass::Int, avg_enter_exit::Int, avg_passengers_beginning::Int, stop_cost::Float64, p_control::Float64, rides_left::Int)
    """
    Function that creates a vehicle instance.

    Arguments:
    - id::Int # identifier for the vehicle
    - n_stops::Int # number of stops on that vehicle route
    - max_pass::Int # maximum capacity of the vehicle
    - avg_enter_exit::Int # average number of passengers entering and exiting the vehicle on a stop
    - avg_passengers_beginning::Int # average number of passengers at the beginning of the ride
    - stop_cost::Float64 # cost of driving the length of a single stop
    - p_control::Float64 # probability of ticket control on the whole route
    - rides_left::Int # number of rides that the vehicle will make during the day

    Returns:
    - Vehicle 
    """
    return Vehicle(
        id,
        n_stops,
        max_pass,
        avg_enter_exit,
        avg_passengers_beginning,
        0,   # początkowa liczba pasażerów
        0,   # początkowa liczba gapowiczów
        round(Int, max_pass / 3),
        stop_cost,
        1 - (1 - p_control)^(1 / n_stops),
        rides_left
    )
end

end