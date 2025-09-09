function private_mask_profile(profile::SpatialFloodProfile)

    sea_mask = falses(size(profile.elevation))
    coast_mask = falses(size(profile.elevation))
    visited = falses(size(profile.elevation))

    @warn "profile.seed: $(profile.seed)"

    sea_value = profile.elevation[profile.seed]
    check_sea_value = idx -> ismissing(sea_value) ? ismissing(profile.elevation[idx]) : profile.elevation[idx] == sea_value

    queue = Queue{CartesianIndex{2}}()
    
    # Mark the seed point as sea and visited
    sea_mask[profile.seed] = true
    visited[profile.seed] = true
    enqueue!(queue, profile.seed)

    while !isempty(queue)
        current_ = dequeue!(queue)
        nb_cells = neighbours(profile.elevation, current_, nb = profile.SpatialKernel) |> values

        for nb in nb_cells
            if !isnothing(nb) && !visited[nb]
                visited[nb] = true
                if check_sea_value(nb)
                    sea_mask[nb] = true
                    enqueue!(queue, nb)
                else
                    coast_mask[nb] = true
                end
            end
        end
    end

    return [coast_mask, sea_mask]

end

struct SpatialFloodProfileMask{Bool}
    coast::Matrix{Bool}
    sea::Matrix{Bool}
    width::Int
    height::Int
end

function SpatialFloodProfileMask(profile::SpatialFloodProfile)
    coast, sea = private_mask_profile(profile::SpatialFloodProfile)
    width, height = size(coast)
    return SpatialFloodProfileMask{Bool}(coast, sea, width, height)
end

function RecipesBase.plot(profile::SpatialFloodProfileMask)

    psettings = Dict(
        :colorbar => false, 
        :aspect_ratio => :equal, 
        :framestyle => :box, 
        :xticks => [1,profile.width],
        :yticks => [1,profile.height]
    )

    p1 = Plots.heatmap(Int.(profile.coast),
        c=[:white, :darkgreen],
        title="Coast Mask";
        psettings ...
        )

    p2 = Plots.heatmap(Int.(profile.sea),
        c=[:white, :darkblue],
        title="Sea Mask";
        psettings ...
        )

    return Plots.plot(p1, p2, layout = (1, 2), size=(1000, 500), legend=false)

end




