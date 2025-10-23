using Agents, Random
using StaticArrays: SVector
@enum LightColor Green Yellow Red

@agent struct TrafficLight(ContinuousAgent{2,Float64})
    color::LightColor
    timer::Int
end

@agent struct Car(ContinuousAgent{2,Float64})
    accelerating::Bool = true
end

accelerate(agent) = agent.vel[1] + 0.05
decelerate(agent) = agent.vel[1] - 0.1

function agent_step!(agent::Car, model)
    new_velocity = agent.accelerating ? accelerate(agent) : decelerate(agent)

    if new_velocity >= 1.0
        new_velocity = 1.0
        agent.accelerating = false
    elseif new_velocity <= 0.0
        new_velocity = 0.0
        agent.accelerating = true
    end
    if agent.id == 1
        println(agent.pos)
    end
    
    agent.vel = (new_velocity, 0.0)
    move_agent!(agent, model, 0.4)
end

function agent_step!(agent::TrafficLight, model)
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
end

function initialize_model(extent = (10, 10))
    space2d = ContinuousSpace(extent; spacing = 0.5, periodic = false)
    rng = Random.MersenneTwister()

    model = StandardABM(TrafficLight, space2d; rng, agent_step!, scheduler = Schedulers.Randomly())

    add_agent!(SVector{2, Float64}(4.0, 6.0), model; color=Green, timer=10, vel=SVector{2, Float64}(0.0, 0.0))
    add_agent!(SVector{2, Float64}(6.0, 4.0), model; color=Green, timer=10, vel=SVector{2, Float64}(0.0, 0.0))
    model
end
