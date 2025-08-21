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

