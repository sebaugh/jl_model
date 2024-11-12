include("ride_functions.jl")

using .StructuresModule
using .RideFunctionsModule


num_vehicles = 10

fleet = Vector{Vehicle}(undef, num_vehicles)

for vehicle in 1:num_vehicles
    fleet[vehicle] = create_vehicle(;id = vehicle, 
                    n_stops = rand(10:20), 
                    max_pass = 120, 
                    avg_enter_exit = rand(1:10), 
                    avg_passengers_beginning = rand(5:30), 
                    stop_cost = 2.00, 
                    p_control = 0.3,
                    rides_left = rand(10:15))
end

print(fleet)