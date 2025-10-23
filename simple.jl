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
        all_agents = collect(allagents(model))
        lights = filter(a -> a.role == Light && a.direction == Horizontal, all_agents)
        
        # only consider lights that are ahead AND in the same lane (within 1.5 units in y)
        ahead_lights = filter(l -> l.pos[1] > agent.pos[1] && abs(l.pos[2] - agent.pos[2]) < 1.5, lights)
        
        if isempty(ahead_lights)
            nearest = nothing
            min_dist = Inf
        else
            nearest = nothing
            min_dist = Inf
            for l in ahead_lights
                d = sqrt((agent.pos[1] - l.pos[1])^2 + (agent.pos[2] - l.pos[2])^2)
                if d < min_dist
                    min_dist = d
                    nearest = l
                end
            end
        end

        stopping_distance = 1.5
        if nearest !== nothing && (nearest.color == Yellow || nearest.color == Red) && min_dist <= stopping_distance
            # are we past the light?????????
            if agent.pos[1] < nearest.pos[1] - 0.2
                agent.vel = SVector{2,Float64}(0.0, 0.0)
                return
            end
        end

        new_velocity = agent.accelerating ? accelerate(agent) : decelerate(agent)

        if new_velocity >= 1.0
            new_velocity = 1.0
            agent.accelerating = false
        elseif new_velocity <= 0.0
            new_velocity = 0.0
            agent.accelerating = true
        end

        agent.vel = SVector{2,Float64}(new_velocity, 0.0)
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

function initialize_model(extent = (10, 10))
    space2d = ContinuousSpace(extent; spacing = 0.5, periodic = false)
    rng = MersenneTwister()

    model = ABM(TrafficAgent, space2d; rng = rng, scheduler = Schedulers.Randomly())

    add_agent!(SVector{2, Float64}(4.0, 6.0), model;
               role = Light, color = Green, timer = 10, direction = Horizontal,
               vel = SVector{2, Float64}(0.0, 0.0), accelerating = false)
    add_agent!(SVector{2, Float64}(6.0, 4.0), model;
               role = Light, color = Green, timer = 10, direction = Vertical,
               vel = SVector{2, Float64}(0.0, 0.0), accelerating = false)

    function sample_x(rng)
        for _ in 1:100
            x = rand(rng) * 2.0
            if x < 3.0
                return x
            end
        end
        return 1.0
    end

    cx = sample_x(rng)
    add_agent!(SVector{2, Float64}(cx, 5.0), model;
               role = Vehicle, color = Green, timer = 0, direction = Horizontal,
               vel = SVector{2, Float64}(0.5, 0.0), accelerating = true)

    return model
end