include("simple.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

route("/simulations", method = POST) do
    payload = jsonpayload()

    #Fetch number of cars
    n_cars = get(payload, "n_cars", 3)

    model = initialize_model(; n_cars_per_street = n_cars)
    id = string(uuid1())
    instances[id] = model

    # return traffic lights and cars
    lights = [Dict(
        "id" => light.id,
        "pos" => collect(light.pos),
        "color" => Int(light.color),
        "timer" => light.timer
    ) for light in allagents(model) if light.role == Light]

    cars = [Dict(
        "id" => car.id,
        "pos" => collect(car.pos),
        "vel" => collect(car.vel),
        "direction" => string(car.direction)
    ) for car in allagents(model) if car.role == Vehicle]

    json(Dict("Location" => "/simulations/$id", "lights" => lights, "cars" => cars))
end

route("/simulations/:id") do
    println(payload(:id))
    model = instances[payload(:id)]
    # step model deterministically: lights then cars
    step_model!(model)

    lights = [Dict(
        "id" => light.id,
        "pos" => collect(light.pos),
        "color" => Int(light.color),
        "timer" => light.timer
    ) for light in allagents(model) if light.role == Light]

    all_cars = [car for car in allagents(model) if car.role == Vehicle]
    cars = [Dict(
        "id" => car.id,
        "pos" => collect(car.pos),
        "vel" => collect(car.vel),
        "direction" => string(car.direction)
    ) for car in all_cars]

    total_speed = 0.0
    if !isempty(all_cars)
        for v in all_cars
            speed_component = (v.direction == Horizontal) ? abs(v.vel[1]) : abs(v.vel[2])
            total_speed += speed_component
        end
        avg_speed = total_speed / length(all_cars)
    else
        avg_speed = 0.0
    end

    json(Dict("lights" => lights, "cars" => cars, "avg_speed" => avg_speed))
end


Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

up()