export damage

# fallback
function damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{String}, ddfs::Vector{Function}, im::IM) where {DT<:Real, IM<:InundationModel}
  # error
end


function damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{String}, ddfs::Vector{Function}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}

end

damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{Symbol}, ddfs::Vector{Function}, im::IM = BathtubInundation())  = damage(hspf, wl, map(x -> String(x),s), ddfs, im) 

function damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{String}, ddfs::Vector{StandardDDF}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}

end

function damage(hspf::HypsometricProfile{DT}, wl::DT, s::Array{Symbol}, ddfs::Vector{StandardDDF}, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel}

end

damage(hspf::HypsometricProfile{DT}, wl::Real, s::String, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [s], [ddf], im)
damage(hspf::HypsometricProfile{DT}, wl::Real, s::Symbol, ddf::Function, im::IM = BathtubInundation()) where {DT<:Real, IM<:InundationModel} = damage(hspf, wl, [String(s)], [ddf], im)


