using DataFrames

"""
A HypsometricProfile represents the variation in elevation from the coastline to inland areas. It can be constructed manually or by using `load_hsps_nc()` and a NetCDF-file.
"""
@kwdef mutable struct HypsometricProfile{DT <: Real}
	width::DT
	width_unit::String
	elevation::Vector{DT}
	elevation_unit::String
	cumulativeArea::Vector{DT}
	area_unit::String
	cumulativeExposure::Matrix{DT}
	exposureNames::Vector{String}
	exposureUnits::Vector{String}
	doLog::Bool
  	distance::Vector{DT} = DT[]
	slope::Vector{DT} = DT[]
	
	# Constructors
	function HypsometricProfile(coast_length::DT, coast_length_unit::String,
		elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
		exposure_data::Array{DT, 2}, exposure_units::Array{String}) where {DT <: Real}
		# String(nameof(var"#self#"))
		if (length(elevations) != length(area))
			@error "length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))"
		end
		if ((size(exposure_data, 1) > 0) && (length(elevations) != size(exposure_data, 1)))
			@error "length(elevations) != size(exposure_data,1)  as length($elevations) != size($exposure_data,1)  as $(length(elevations)) != $(size(exposure_data,1))"
		end
		if (length(elevations) < 2)
			@error "length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed"
		end
		if (!issorted(elevations))
			@error "elevations is not sorted: $elevations"
		end
		if (area[1] != 0)
			@error " area[1] should be zero, but its not: $area"
		end

		new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims = 1), map(i -> "exposure_data_name_$i", collect(1:size(exposure_data, 2))), exposure_units)
	end


	function HypsometricProfile(coast_length::DT, coast_length_unit::String,
		elevations::Array{DT}, elevation_unit::String, area::Array{DT}, area_unit::String,
		exposure_data::Array{DT, 2}, exposure_names::Array{String}, exposure_units::Array{String}) where {DT <: Real}
		# String(nameof(var"#self#"))
		if (length(elevations) != length(area))
			@error "length(elevations) != length(area) as length($elevations) != length($area) as $(length(elevations)) != $(length(area))"
		end
		if ((size(exposure_data, 1) > 0) && (length(elevations) != size(exposure_data, 1)))
			@error "length(elevations) != size(exposure_data,1)  as length($elevations) != size($exposure_data,1)  as $(length(elevations)) != $(size(exposure_data,1))"
		end
		if (length(elevations) < 2)
			@error "length(elevations) = length($elevations) = $(length(elevations)) < 2 which is not allowed"
		end
		if (!issorted(elevations))
			@error "elevations is not sorted: $elevations"
		end
		if (exposure_names != unique(exposure_names))
			@error "exposure_names has duplicates: $exposure_names"
		end
		if (area[1] != 0)
			@error "area[1] should be zero, but its not: $area"
		end

		new{DT}(coast_length, coast_length_unit, elevations, elevation_unit, cumsum(area), area_unit, cumsum(exposure_data, dims = 1), exposure_names, exposure_units)
	end

	function HypsometricProfile(df::DataFrame; exposureCols = Symbol[], exposureUnits = String[], units = (width = "m", elevation = "m", area = "m²"))

		exportData = vcat([hcat(values(row)...) for row in eachrow(df[:, exposureCols])]...)

		new{Float32}(df.width[1], units.width,
			df.elevation, units.elevation,
			df.cumulativeArea, units.area,
			exportData,
			String.(exposureCols),
			exposureUnits)
	end

end

"""
   distance(hspf::HypsometricProfile, e::Real)
  
Compute the distance of elevation e (given in m) from the coastline in hspf. disatnce is returned in km.
"""
function distance(hspf::HypsometricProfile{DT}, e::Real)::DT where {DT <: Real}
	return private_distance(hspf.elevation, hspf.cumulativeArea, hspf.width, e)
end

function private_distance(elevation::Vector{DT}, cumulativeArea::Vector{DT}, width::DT, e::Real)::DT where {DT <: Real}

	inv_w = inv(width) # Inverse of width to avoid repeated division and do multiplication instead - performance
	d = zero(DT) # Initialize the distance to zero - using zero(DT) to ensure the type is correct (type stability)

	@inbounds if (e <= first(elevation))
		return d
	end

	ind::Int64 = searchsortedfirst(elevation, e) # Find the index of the first element in elevation that is greater than or equal to e

	# Calculate distances for all full segments before the index of e and cumulate them
	@inbounds for i in 2:(ind-1)

		Δ_area = cumulativeArea[i] - cumulativeArea[i-1] # Calculate the change in area between the current and previous index
		Δ_e = (elevation[i] - elevation[i-1]) * 1e-3 # Calculate the change in elevation between the current and previous index, converting to km
		hyopthenuse = Δ_area * inv_w # Calculate the hypotenuse of the triangle formed by the change in area and width
		Δ_distance = hyopthenuse * hyopthenuse - Δ_e * Δ_e # Applying the Pythagorean theorem to calculate the change in distance from the coastline, given the change in area and elevation
		if Δ_distance > 0
			d += sqrt(Δ_distance) # If the calculated change in distance is positive, add it to the total distance
		end

	end

	# For the last segment, calculate the distance from the last elevation point to e
	if ind <= length(elevation)

		@inbounds begin
			Δ_e = (elevation[ind] - elevation[ind-1]) * 1e-3 # Calculate the change in elevation in the last segment, converting to km
			Δ_e_partial = (e - elevation[ind-1]) * 1e-3  # Partial segment height from elevation[ind-1] up to e, in km
			Δ_area = (cumulativeArea[ind] - cumulativeArea[ind-1]) * (Δ_e_partial / Δ_e) # Calculate the change in area for the last segment, scaled by the relative change in elevation
			hyp = Δ_area * inv_w
			Δ_distance = hyp*hyp - Δ_e_partial * Δ_e_partial
			if Δ_distance > 0
				d += sqrt(Δ_distance) # If the calculated change in distance is positive, add it to the total distance
			end
		end
	end
	return d

end

function private_distances(elevation::Vector{DT}, cumulativeArea::Vector{DT}, width::DT) where {DT <: Real}

    n = length(elevation) # Length of the elevation vector
    cum_dist = Vector{DT}(undef, n) # Initialize a vector to store cumulative distances, with the same length as the elevation vector

    cum_dist[1] = zero(DT) # Distance at the first elevation point is zero
    inv_w = inv(width) # Inverse the width to avoid repeated division and do multiplication instead - performance

    @inbounds for i in 2:n 
      Δ_area = cumulativeArea[i] - cumulativeArea[i-1] # Calculate the change in area between the current and previous index
      Δ_e = (elevation[i] - elevation[i-1]) * 1e-3  # Calculate the change in elevation between the current and previous index, converting to km
      hyopthenuse    = Δ_area * inv_w # Calculate the hypotenuse of the triangle formed by the change in area and width
      Δ_distance = hyopthenuse * hyopthenuse - Δ_e * Δ_e # Applying the Pythagorean theorem to calculate the change in distance from the coastline, given the change in area and elevation
      segment_distance = Δ_distance > 0 ? sqrt(Δ_distance) : zero(DT) # If the calculated change in distance is positive, use it; otherwise, set it to zero
      cum_dist[i] = cum_dist[i-1] + segment_distance # Cumulatively add the segment distance to the total distance
    end

    return cum_dist
end

function distance!(hspf::HypsometricProfile{DT}) where {DT <: Real}
  hspf.distance = private_distances(hspf.elevation, hspf.cumulativeArea, hspf.width)
  return hspf.distance
end

# Important: returned unit is km/km (or m/m ...)
function slope(hspf::HypsometricProfile{DT}, i::Int) where {DT <: Real}
	return private_slope(hspf.elevation, hspf.cumulativeArea, hspf.width, i)
end

# Slope function to pre-calculate slopes for not-yet existing HypsometricProfiles
function private_slope(elevation::Vector{DT}, cumulativeArea::Vector{DT}, width::DT, i::Int) where {DT <: Real}
	i <= 1 && return Inf
	n = length(elevation)
	if (i > n)
		# Take the last two points to calculate the slope, as we are beyond the last point
		return (width / (cumulativeArea[n] - cumulativeArea[n-1])) * (elevation[n] - elevation[n-1]) * convert(DT, 0.001)
	else
		# Take the points at index i and i-1 to calculate the slope
		return (width / (cumulativeArea[i] - cumulativeArea[i-1])) * (elevation[i] - elevation[i-1]) * convert(DT, 0.001)
	end
end

function private_slopes(elevation::Vector{DT}, cumulativeArea::Vector{DT}, width::DT) where {DT <: Real}
    n = length(elevation) # Length of the elevation vector
    slopes = Vector{DT}(undef, n) # Initialize a vector to store slopes, with the same length as the elevation vector

    slopes[1] = Inf # Slope at the first elevation point is infinite (or undefined)
    
    @inbounds for i in 2:n 
        slopes[i] = (width / (cumulativeArea[i] - cumulativeArea[i-1])) * (elevation[i] - elevation[i-1]) * convert(DT, 0.001) # Calculate the slope for each segment
    end

    return slopes
end

function slope!(hspf::HypsometricProfile{DT}) where {DT <: Real}
  hspf.slope = private_slopes(hspf.elevation, hspf.cumulativeArea, hspf.width)
  return hspf.slope
end

function resample!(hspf::HypsometricProfile{DT}, elevation::Array{DT}; recalculate_slopes::Bool=false, 
	recalculate_distances::Bool=false) where {DT <: Real}
	if (hspf.elevation != elevation)
		el = copy(elevation)

		if (hspf.elevation[1] < el[1])
			pushfirst!(el, hspf.elevation[1])
		end

		can = Array{DT}(undef, size(el, 1))
		cden::Array{DT, 2} = Array{DT, 2}(undef, size(el, 1), size(hspf.cumulativeExposure, 2))

		for i in 1:size(el, 1)
			t_exposure = exposure(hspf, el[i])
			can[i] = t_exposure[1]
			cden[i, :] = t_exposure[2]
		end

		hspf.elevation = el
		hspf.cumulativeArea = can
		hspf.cumulativeExposure = cden

	# Check if distance, and slope are already calculated, if so, recalculate them
		if recalculate_distances
			distance!(hspf)
		else
			hspf.distance = DT[] # Invalidate the distance vector if not recalculating
		end

		if recalculate_slopes
			slope!(hspf)
		else
			hspf.slope = DT[] # Invalidate the slope vector if not recalculating
		end

	end
end


"""
	compress!(hspf::HypsometricProfile)
  
Comress a hypsometric profile by removing colinear points. Calculations on compressed hypsometric profiles can be faster. Idempotent operation.
"""
function compress!(hspf::HypsometricProfile{DT}; recalculate_slopes::Bool=false, 
	recalculate_distances::Bool=false) where {DT <: Real}
	if (size(hspf.elevation, 1) > 2)
		i = 2
		d = 0
		keep = ones(Bool, size(hspf.elevation, 1))
		nzlf = false

		while i < size(hspf.elevation, 1) && !nzlf
			if (complete_zero(exposure(hspf, hspf.elevation[i-1])) && complete_zero(exposure(hspf, hspf.elevation[i])))
				keep[i-1] = false
				d = d + 1
			else
				nzlf = true
			end
			i += 1
		end

		for j in i:(size(hspf.elevation, 1)-1)
			if private_colinear_lines(hspf, j - 1, j, j + 1, !nzlf)
				keep[j] = false
				d = d + 1
			end
		end

		# OLD:
		#newElevation = zeros(DT, size(hspf.elevation, 1) - d)
		#newCumulativeArea = zeros(DT, size(hspf.elevation, 1) - d)
		newCumulativeExposure = zeros(DT, size(hspf.cumulativeExposure, 1) - d, size(hspf.cumulativeExposure, 2))

		c = 1
		for i in 1:size(hspf.elevation, 1)
			if (keep[i])
				hspf.elevation[c] = hspf.elevation[i]
				hspf.cumulativeArea[c] = hspf.cumulativeArea[i]
				newCumulativeExposure[c, :] = hspf.cumulativeExposure[i, :]
				c += 1
			end
		end

		resize!(hspf.elevation, c - 1)
		resize!(hspf.cumulativeArea, c - 1)
		hspf.cumulativeExposure = newCumulativeExposure

		# Check if distance, and slope are already calculated, if so, recalculate them
		if recalculate_distances
			distance!(hspf)
		else
			hspf.distance = DT[] # Invalidate the distance vector if not recalculating
		end
		if recalculate_slopes
			slope!(hspf)
		else
			hspf.slope = DT[] # Invalidate the slope vector if not recalculating
		end
	end
end

function compress_multithread!(hspf::HypsometricProfile{DT}, mtlock;
	recalculate_slopes::Bool=false, recalculate_distances::Bool=false) where {DT <: Real}
	if (size(hspf.elevation, 1) > 2)
		i = 2
		d = 0
		keep = ones(Bool, size(hspf.elevation, 1))
		nzlf = false

		while i < size(hspf.elevation, 1) && !nzlf
			if (complete_zero(exposure(hspf, hspf.elevation[i-1])) && complete_zero(exposure(hspf, hspf.elevation[i])))
				keep[i-1] = false
				d = d + 1
			else
				nzlf = true
			end
			i += 1
		end

		for j in i:(size(hspf.elevation, 1)-1)
			if private_colinear_lines(hspf, j - 1, j, j + 1, !nzlf)
				keep[j] = false
				d = d + 1
			end
		end

		# OLD:
		#newElevation = zeros(DT, size(hspf.elevation, 1) - d)
		#newCumulativeArea = zeros(DT, size(hspf.elevation, 1) - d)
		newCumulativeExposure = zeros(DT, size(hspf.cumulativeExposure, 1) - d, size(hspf.cumulativeExposure, 2))

		c = 1
		for i in 1:size(hspf.elevation, 1)
			if (keep[i])
				Threads.lock(mtlock) do
					hspf.elevation[c] = hspf.elevation[i]
					hspf.cumulativeArea[c] = hspf.cumulativeArea[i]
				end
				newCumulativeExposure[c, :] = hspf.cumulativeExposure[i, :]
				c += 1
			end
		end

		
		Threads.lock(mtlock) do
			resize!(hspf.elevation, c - 1)
			resize!(hspf.cumulativeArea, c - 1)
			hspf.cumulativeExposure = newCumulativeExposure
			if recalculate_distances
				distance!(hspf)
			else
				hspf.distance = DT[] # Invalidate the distance vector if not recalculating
			end
			if recalculate_slopes
				slope!(hspf)
			else
				hspf.slope = DT[] # Invalidate the slope vector if not recalculating
			end
		end
	end
end

function get_position(hspf::HypsometricProfile, s::String)
	if (s == "area")
		return 0
	end
	if (findfirst(==(s), hspf.exposureNames) != nothing)
		return findfirst(==(s), hspf.exposureNames)
	end
	return -1
end

get_position(hspf::HypsometricProfile, n::Symbol) = get_position(hspf, String(n))

"""
	unit(hspf::HypsometricProfile, s::Symbol)  
	unit(hspf::HypsometricProfile, s::String)    

	returns the unit (of type String) of the exposure variable with name s (where s can be a string or a symbol)
"""
function unit(hspf::HypsometricProfile, s::String)
	p = get_position(hspf, s)
	if (p == 0)
		return hspf.area_unit
	end
	if (p > 0)
		return hspf.exposureUnits[p]
	end
	return "unknown symbol: $s"
end

unit(hspf::HypsometricProfile, n::Symbol) = unit(hspf, String(n))

function complete_zero(exposure::Tuple{DT, Vector{DT}}) where {DT <: Real}
	if (exposure[1] != 0)
		return false
	end
	if length(exposure) == 1
		return true
	else
		for i in 1:size(exposure[2], 1)
			if exposure[2][i] != 0
				return false
			end
		end
		return true
	end
end

function complete_zero(exposure::Array{DT}) where {DT <: Real}
	for i in 1:size(exposure, 1)
		if exposure[i] != 0
			return false
		end
	end
	return true
end

function private_colinear_lines(hspf::HypsometricProfile, i1::Int64, i2::Int64, i3::Int64, check_zero::Bool)::Bool
	ex1 = exposure(hspf, hspf.elevation[i1])
	ex2 = exposure(hspf, hspf.elevation[i2])
	ex3 = exposure(hspf, hspf.elevation[i3])
	r = (hspf.elevation[i2] - hspf.elevation[i1]) / (hspf.elevation[i3] - hspf.elevation[i1])
	# hack to capture special case that makes problems (if e3 is very small)
	if (check_zero && complete_zero(ex2) && !complete_zero(ex3))
		return false
	end
	return isapprox(ex2[1], ex1[1] + r * (ex3[1] - ex1[1])) && isapprox(ex2[2], ex1[2] + r * (ex3[2] - ex1[2]))
end
