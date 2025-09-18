struct HydraulicConnectedBathtub <: InundationModel
    function HydraulicConnectedBathtub()
        return new()
    end
end


struct PathBasedAttenuatedBathtub <: InundationModel
    attrate::Union{Real, GeoArrays.GeoArray, AbstractMatrix}
    function PathBasedAttenuatedBathtub(attrate::Union{Real, GeoArrays.GeoArray, AbstractMatrix})
        return new(attrate)
    end
end

function Base.show(io::IO, im::Union{HydraulicConnectedBathtub, PathBasedAttenuatedBathtub})
   
    if im isa HydraulicConnectedBathtub
        print(io, "<DIVACoast.jl | HCB Model>")
    elseif im isa PathBasedAttenuatedBathtub
        print(io, "<DIVACoast.jl | PBAB Model>")
    end
end