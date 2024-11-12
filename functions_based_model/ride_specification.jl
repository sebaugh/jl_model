function ride_specification(max_pass)
    """Function that creates the arguments that define different bus routes. 

    Arguments:
    - max_pas::Int - maximum capacity of the buses

    Returns a named tuple:
        - n_stops::Int - length of the bus ride defined by the number of possible stops
        - max_pass::Int - maximum capacity of the buses
        - avg_bus::Int - predicted average number of passengers embarking/exiting the bus at a stop
        - n_passengers::Int - average number of passengers embarking at the beginning of the ride
        - n_trips::Int - number of trips during one period for this bus ride type
    """

    n_stops = rand(10:20)
    avg_bus = min(rand(Distributions.Poisson(15)), Int(max_pass/3))
    n_passengers = 15
    n_trips = rand(10:15)
    (; n_stops, max_pass, avg_bus, n_passengers, n_trips)
end
