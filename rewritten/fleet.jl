include("vehicle.jl")

vehicles_in_fleet = 10

for _ in 1:vehicles_in_fleet
    create_vehicle(id = _,)
end