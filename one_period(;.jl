function one_period(;
    n_control = 10,
    ndays = 30,
    max_pas = 60,
    stop_cost = 20,
    ticket_price = 5,
    pass_cost = 5,
    ticket_penalty = 20,
    n_bus = 50,
    control_cost = 50)
    """ Function that simulates one period for the bus rides, there is a call to functions ride_specification that creates a dataframe which consists of parameters for all of the bus rides for the period which as a default is a month. After creating the dataframe, there is a for look that iterates through the number of days for every day, iterates through the range based on the highest number of trips that all rides have. Then it iterates through the buses checking if the current number of trips is lower or equal to the planned number of trips for that ride, then there is a call to the function bus_ride with passing all the arguments from the bus_par, and day_revenue gets calculated. The function returns total revenue for the period, a list with daily revenues and a list with number of all controls left.

    Arguments:
    - n_control::Int - maximum number of all ticket controls during the whole period
    - ndays::Int - length of the period in days
    - max_pas::Int - maximum capacity of the buses used
    - stop_cost::    
    """
    bus_par = DataFrame(bus_p(max_pas) for _ in 1:n_bus)

    control_left = []
    max_trips = maximum(bus_par.n_trips)
    total_revenue = 0.0
    day_rev = Float64[]

    #simulating days
    for day in 1:ndays
        control_num = n_control
        day_revenue = 0.0

        for i in 1:max_trips
            for bus in 1:n_bus
                if bus_par.n_trips[bus] >= i
                    ride_rev, control_num = bus_ride(
                        n_stops = bus_par.n_stops[bus], 
                        max_pass = bus_par.max_pass[bus], 
                        avg_bus = bus_par.avg_bus[bus], 
                        n_passengers = bus_par.n_passengers[bus], 
                        n_control = control_num,
                        stop_cost = stop_cost,
                        ticket_price = ticket_price,
                        pass_cost = pass_cost,
                        ticket_penalty = ticket_penalty,
                        control_cost = control_cost)
                    day_revenue += ride_rev
                end
            end
        end

        push!(control_left, control_num)
        total_revenue += day_revenue
        push!(day_rev, day_revenue)
    end
    (; total_revenue, day_rev, control_left)
end
