struct spatialDataMock()

    elevation::Array{Float32,2}
    wbm::Array{Bool,2}
    population::Array{Float32,2}
    
end

function SpatialDataMock(width::Int, height::Int, max_elev::Float32, max_pop::Float32, seed::Int = 42)

    sampler = perlin_2d(seed = seed, frequency = 0.1)

    return spatialDataMock(elev_, wbm_, pop_)
end



function elevation(width, height, max_elev)

    elev_ = zeros(Float32, width, height)
    for i in 2:width
        elev_[i, :] .= elev_[i - 1, :] .+ (max_elev / width)
    end

    return transpose(elev_)
end

function wbm(width, height)
    wbm = falses(width, height) 
    wbm[1, :] .= true
    return transpose(wbm)
end


function population(width, height, max_pop)

    spread = 5
    sd = 0.3
    spawnProb = 0.5
    nα = Int(width * height * 0.01)

    seed_indices = [CartesianIndex(rand(2:width), rand(1:height)) for _ in 1:nα]
    
    pop_ = zeros(Float32, width, height)
    for idx in seed_indices
        pop_[idx] = rand(0.0:max_pop)
    end

    kernel = SpatialCursorRadial(8)

    sum = 0.0
    count = 0

    for seedidx in seed_indices
        nbs = neighbours(pop_, seedidx; nb = kernel, returndist = true) |> values |> collect 
        idxs, dists = collect.(zip(nbs ...)) 
        for (idx, dist) in zip(idxs, dists)
            if isnothing(idx) || isnothing(dist)
                continue
            end
            influence = max(0, (spread - dist) / spread)
            pop_[idx] += rand(0.0:max_pop * influence * sd)
        end
    end
    return transpose(pop_)
end




