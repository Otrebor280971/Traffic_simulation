using Agents, Random
using StaticArrays: SVector

@enum LightColor Green Yellow Red
@enum AgentRole Light Vehicle
@enum LightDirection Horizontal Vertical

@agent struct TrafficAgent(ContinuousAgent{2,Float64})
    # THIS IS SO DIRTY SORRY BETO
    role::AgentRole
    color::LightColor
    timer::Int
    direction::LightDirection
    accelerating::Bool
end

accelerate(agent) = agent.vel[1] + 0.05
decelerate(agent) = agent.vel[1] - 0.1

function agent_step!(agent::TrafficAgent, model)
    # LIGHTTTT
    if agent.role == Light
        agent.timer -= 1
        if agent.timer <= 0
            if agent.color == Green
                agent.color = Yellow
                agent.timer = 4
            elseif agent.color == Yellow
                agent.color = Red
                agent.timer = 14
            elseif agent.color == Red
                agent.color = Green
                agent.timer = 10
            end
        end
    else
        # CARRR

        # define movement axis and important ligts
        local axis, cross_axis
        if agent.direction == Horizontal
            axis = 1 # x
            cross_axis = 2 #y
        else
            axis = 2 #y
            cross_axis = 1 #x
        end

        all_agents = collect(allagents(model))
        lights = filter(a -> a.role == Light && a.direction == agent.direction, all_agents)
        
        # only consider lights that are ahead AND in the same lane (within 1.5 units in y)
        ahead_lights = filter(l -> l.pos[axis] > agent.pos[axis] && abs(l.pos[cross_axis] - agent.pos[cross_axis]) < 1.5, lights)
        
        nearest = nothing
        min_dist = Inf
        
        if !isempty(ahead_lights)
            for l in ahead_lights
                d = sqrt((agent.pos[1] - l.pos[1])^2 + (agent.pos[2] - l.pos[2])^2)
                if d < min_dist
                    min_dist = d
                    nearest = l
                end
            end
        end

        #find closest car ahead and in same lane
        vehicles = filter(a -> a.role == Vehicle && a.id != agent.id && a.direction == agent.direction, all_agents)
        ahead_vehicles = filter(v -> v.pos[axis] > agent.pos[axis] && abs(v.pos[cross_axis] - agent.pos[cross_axis]) < 1.5, vehicles)

        nearest_vehicle = nothing
        min_dist_vehicle = Inf
        if !isempty(ahead_vehicles)
            for v in ahead_vehicles
                d = sqrt((agent.pos[1] - v.pos[1])^2 + (agent.pos[2] - v.pos[2])^2)
                if d < min_dist_vehicle
                    min_dist_vehicle = d
                    nearest_vehicle = v
                end
            end
        end

        light_stop = 1.5
        car_safety = 1.0

        if( nearest !== nothing && (nearest.color == Yellow || nearest.color == Red) && min_dist <= light_stop && agent.pos[axis] <  nearest.pos[axis] - 0.2 ) || (nearest_vehicle !== nothing && min_dist_vehicle <= car_safety)
            agent.vel = SVector{2, Float64}(0.0, 0.0)
            agent.accelerating = true
            return
        end

        current_velocity_component = agent.vel[axis]
        max_speed = 1.0

        if current_velocity_component >= max_speed
            agent.accelerating = false
        elseif current_velocity_component <= 0.0
            agent.accelerating = true
        end

        new_velocity = agent.accelerating ? (current_velocity_component + 0.05) : (current_velocity_component - 0.1)

        if new_velocity >= max_speed
            new_velocity = max_speed
        elseif new_velocity <= 0.0
            new_velocity = 0.0
        end

        #update speed vector based on direction
        if agent.direction == Horizontal
            agent.vel = SVector{2,Float64}(new_velocity, 0.0)
        else
            agent.vel = SVector{2, Float64}(0.0, new_velocity)
        end

        move_agent!(agent, model, 0.4)
    end
end

# lights first, then cars
function step_model!(model)
    for a in allagents(model)
        if a.role == Light
            agent_step!(a, model)
        end
    end
    for a in allagents(model)
        if a.role == Vehicle
            agent_step!(a, model)
        end
    end
end

function initialize_model(extent = (10, 10); n_cars_per_street = 3)
    space2d = ContinuousSpace(extent; spacing = 0.5, periodic = false)
    rng = MersenneTwister()

    model = ABM(TrafficAgent, space2d; rng = rng, scheduler = Schedulers.Randomly())

    #Horizontal light
    add_agent!(SVector{2, Float64}(4.0, 6.0), model;
               role = Light, color = Green, timer = 10, direction = Horizontal,
               vel = SVector{2, Float64}(0.0, 0.0), accelerating = false)
    #Vertical light
    add_agent!(SVector{2, Float64}(6.0, 4.0), model;
               role = Light, color = Red, timer = 14, direction = Vertical,
               vel = SVector{2, Float64}(0.0, 0.0), accelerating = false)

    #Add n cars in Horizontal
    for _ in 1:n_cars_per_street
        start_x = rand(rng) *3.5
        start_vel = rand(rng) * 0.8
        add_agent!(SVector{2, Float64}(start_x, 6.0), model;
                    role = Vehicle, color = Green, timer = 0, direction = Horizontal,
                    vel = SVector{2, Float64}(start_vel, 0.0), accelerating = true)
    end

    #Add n cars in Vertical
    for _ in 1:n_cars_per_street
        start_y = rand(rng) * 3.5
        start_vel = rand(rng) * 0.8
         add_agent!(SVector{2, Float64}(6.0, start_y), model;
                   role = Vehicle, color = Green, timer = 0, direction = Vertical,
                   vel = SVector{2, Float64}(0.0, start_vel), accelerating = true)
    end
    return model
end