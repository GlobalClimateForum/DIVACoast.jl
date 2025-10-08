using GeoArrays

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

# SpatialProfileMask constructor from SpatialFloodProfile
function SpatialFloodProfileMask(profile::SpatialFloodProfile)
    
    coast, sea = private_mask_profile(profile::SpatialFloodProfile)
    coast = GeoArrays.GeoArray(coast, profile.elevation.f, profile.elevation.crs)
    sea = GeoArrays.GeoArray(sea, profile.elevation.f, profile.elevation.crs)
    
    width, height = size(coast)
    return SpatialFloodProfileMask{Bool}(coast, sea, width, height)
end

# SpatialProfileMask constructor from Waterbodies Mask (Copernicus WBM is default mapping)
function SpatialFloodProfileMask(
    waterbodies::AbstractArray{T, 2}; 
    mapping::Dict{Union{Symbol, String}, T} = Dict(:nowater => 0.0, :ocean => 1.0, :lake => 2.0, :river => 3.0)
    ) where T <: Real


    sea = falses(size(waterbodies))
    sea[waterbodies .=== mapping[:ocean]] .= true

    coast = falses(size(waterbodies))

    for cell in findall(!sea)
        nb_cells = neighbours(sea, cell, nb = Neighbour8()) |> values
        if any(nb_cells .=== true)
            coast[cell] = true
        end
    
    end
    

    width, height = size(waterbodies)
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

    if (profile.coast isa GeoArrays.GeoArray && profile.sea isa GeoArrays.GeoArray)

        @info "Plot as GeoArrays.GeoArray"
    
        p1 = plot(profile.coast; title = "Coast Mask",  psettings ...)
        p2 = plot(profile.sea; title = "Sea Mask",  psettings ...)
    
    else
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
    end
    return Plots.plot(p1, p2, layout = (1, 2), size=(1000, 500), legend=false)
end




